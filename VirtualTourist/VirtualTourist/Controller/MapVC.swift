//
//  MapVC.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/8/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataController: DataController!
    
    var editingEnabled : Bool = false
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var deletePinsLabel: MapVCDeletePinsLabel!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBAction func editBarButton(_ sender: Any) {
        performUIUpdatesOnMain {
            self.editingEnabled ? self.shiftDeletePinsLabelUp() : self.shiftDeletePinsLabelDown()
        }
    }
    
    var pins : [Pin] = []
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    var annotations : [MKAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !checkForInternet() {
            performUIUpdatesOnMain {
                showAlert(controller: self, title: "No Internet Connection", error: ErrorMessages.connectionError.stringValue, actions: [okayAlertAction])
            }
        }

        self.title = "Virtual Tourist"
        map.delegate = self
        addGesture()
        setupFetchedResultsControllerAndGetPins()
        
        if !pins.isEmpty {
            for pin in pins {
                addPin(coordinates: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            }
        }
    }
    
    // HIDE LABEL
    func shiftDeletePinsLabelUp() {
        self.editBarButton.title = "Edit"
        self.editingEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.deletePinsLabel.frame = CGRect(x: self.deletePinsLabel.frame.minX, y: self.deletePinsLabel.frame.minY-40, width: self.deletePinsLabel.frame.width, height: self.deletePinsLabel.frame.height)
        }
    }
    
    // SHOW LABEL
    func shiftDeletePinsLabelDown() {
        self.editBarButton.title = "Done"
        self.editingEnabled = true
        UIView.animate(withDuration: 0.5) {
            self.deletePinsLabel.frame = CGRect(x: self.deletePinsLabel.frame.minX, y: self.deletePinsLabel.frame.minY+40, width: self.deletePinsLabel.frame.width, height: self.deletePinsLabel.frame.height)
        }
    }
    
}

extension MapVC: NSFetchedResultsControllerDelegate {
    
    // SETUP FETCHED RESULTS CONTROLLER
    // SETUP PINS ARRAY
    @discardableResult func setupFetchedResultsControllerAndGetPins() -> [Pin]? {
        // set up fetched results controller
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // set up pins array
        do {
            let totalPins = try fetchedResultsController.managedObjectContext.count(for: fetchRequest)
            for i in 0..<totalPins {
                pins.append(fetchedResultsController.object(at: IndexPath(row: i, section: 0)))
            }
            return pins
        } catch {
            return nil
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editingEnabled {
            removePin(annotation: view.annotation!)
        } else {
            performSegue(withIdentifier: "pinTapped", sender: view.annotation?.coordinate)
            map.deselectAnnotation(view.annotation, animated: true)
        }
    }
    
    func addGesture() {
        let longTouchGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTouch(_:)))
        longTouchGesture.minimumPressDuration = 1.0
        map.addGestureRecognizer(longTouchGesture)
    }
    
    @objc func longTouch(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchLocation = gestureRecognizer.location(in: map)
            let coordinates = map.convert(touchLocation, toCoordinateFrom: map)
            addPin(coordinates: coordinates)
            
            // Save pin to CoreData
            let pin = Pin(context: dataController.persistentContainer.viewContext)
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            pins.append(pin)
            try? dataController.persistentContainer.viewContext.save()
        }
    }
    
    func addPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        map.addAnnotation(annotation)
        annotations.append(annotation)
        map.showAnnotations(annotations, animated: true)
    }
    
    func removePin(annotation: MKAnnotation) {
        for pin in pins {
            if pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude {
                do {
                    pins.removeAll(where: {$0.latitude == pin.latitude && $0.longitude == pin.longitude})
                    dataController.persistentContainer.viewContext.delete(pin)
                    try dataController.persistentContainer.viewContext.save()
                } catch {
                    performUIUpdatesOnMain {
                        showAlert(controller: self, title: "Oops!", error: ErrorMessages.removePinError.stringValue, actions: [okayAlertAction])
                    }
                }
            }
        }
        map.removeAnnotation(annotation)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTapped" {
            if let locationFeedVC = segue.destination as? LocationFeedVC {
                let coordinatesToPass = sender as! CLLocationCoordinate2D
                locationFeedVC.coordinates = coordinatesToPass
                
                for pin in pins {
                    if pin.latitude == coordinatesToPass.latitude && pin.longitude == coordinatesToPass.longitude {
                        locationFeedVC.pin = pin
                        locationFeedVC.dataController = dataController
                    }
                }
            }
        }
    }
    
}
