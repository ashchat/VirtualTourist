//
//  LocationFeedVC.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/16/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationFeedVC: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var directionsLabel: LocationsFeedVCLabel!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pin: Pin!
    var coordinates: CLLocationCoordinate2D!
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var photosCD: [Photo] = []
    
    var page = 1
    var pages = INT_MAX
    
    var editingEnabled = false
    var selectedIndexes : [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initNavBar()
        initCV()
        initMap()
        
        let photos = setupFetchedResultsControllerAndGetPhotos()
        if photos != nil && photos?.count != 0 {
            page = Int(pin.page)
            pages = pin.pages
            photosCD = photos!
            print(photos!.count)
            self.collectionView.reloadData()
        } else {
            getPhotos()
        }
    }
    
    func initNavBar() {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            
            self.title = placemark.subAdministrativeArea!
        }
        
        setBarButtonItem()
    }
    
    func setBarButtonItem() {
        switch editingEnabled {
        case true:
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSelectedPhotos))
        case false:
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadPhotos))
        }
        
        directionsLabel.setLabelUI(editingEnabled)
    }
    
    @objc func reloadPhotos() {
        print(photosCD)
        removePhotosFromCoreData()
        page+=1
        getPhotos()
        collectionView.reloadData()
    }
    
    func getPhotos() {
        
        if self.page > self.pages {
            self.page = 1
        }
        
        FlickrClient.taskForGETFlickrImages(lat: Double(coordinates.latitude), long: Double(coordinates.longitude), page: page) { (response, error) in
            guard let response = response else {
                print(error!)
                return
            }
            self.pages = Int32(response.photos.pages)
            self.savePhotosToCoreData(images: response.photos.images, pin: self.pin)
        }
        
    }
}

extension LocationFeedVC: NSFetchedResultsControllerDelegate {
    
    func setupFetchedResultsControllerAndGetPhotos() -> [Photo]? {
        // set up fetched results controller
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // set up photos array
        var photos : [Photo] = []
        do {
            let totalPhotos = try fetchedResultsController.managedObjectContext.count(for: fetchRequest)
            for i in 0..<totalPhotos {
                photos.append(fetchedResultsController.object(at: IndexPath(row: i, section: 0)))
            }
            return photos
        } catch {
            return nil
        }
    }
    
    func savePhotosToCoreData(images: [FlickrImage], pin: Pin) {
        pin.page = Int32(page)
        pin.pages = Int32(pages)
        for image in images {
            let photo = Photo(context: dataController.persistentContainer.viewContext)
            photo.imageData = nil
            photo.pin = pin
            photo.imageURL = image.photoURL()
            photosCD.append(photo)
            do {
                try dataController.persistentContainer.viewContext.save()
            } catch {
                print("Couldn't save to Core Data")
            }
        }
        self.collectionView.reloadData()
    }
    
    func removePhotosFromCoreData() {
        for photoCD in photosCD {
            dataController.viewContext.delete(photoCD)
        }
        do {
            photosCD.removeAll()
            try dataController.persistentContainer.viewContext.save()
        } catch {
            print("Couldn't delete from Core Data")
        }
    }
    
    @objc func deleteSelectedPhotos() {
        for indexPath in (self.collectionView!.indexPathsForSelectedItems)! {
            dataController.persistentContainer.viewContext.delete(photosCD[indexPath.row])
            self.collectionView.deselectItem(at: indexPath, animated: false)
        }
        do {
            try dataController.persistentContainer.viewContext.save()
        } catch {
            print("Couldn't delete from Core Data")
        }
        photosCD = setupFetchedResultsControllerAndGetPhotos()!
        editingEnabled = false
        setBarButtonItem()
        collectionView.reloadData()
    }
    
}

extension LocationFeedVC: MKMapViewDelegate {
    
    func initMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        map.addAnnotation(annotation)
        self.map.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        map.setRegion(region, animated: true)
    }
    
}

extension LocationFeedVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func initCV() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.setCollectionViewLayout(CVFlowLayout(), animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosCD.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CVCell", for: indexPath) as! CVCell
        cell.loadImage(photosCD[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        editingEnabled = true
        setBarButtonItem()
        let cell = collectionView.cellForItem(at: indexPath)
        performUIUpdatesOnMain {
            cell?.alpha = 0.5
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            editingEnabled = false
            setBarButtonItem()
        }
        let cell = collectionView.cellForItem(at: indexPath)
        performUIUpdatesOnMain {
            cell?.alpha = 1.0
        }
    }
    
    func CVFlowLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumLineSpacing = 1
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.itemSize = CGSize(width: (self.view.frame.width/3)-1, height: (self.view.frame.width/3)-1)
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }
    
}
