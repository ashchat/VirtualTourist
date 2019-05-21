//
//  CVCell.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/16/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import UIKit

class CVCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    override func awakeFromNib() {
        initImageView()
    }
    
    func initImageView() {
        self.backgroundColor = UIColor.clear
        // Set the background color randomly for more fun UI
        // in case the image hasn't loaded yet
        contentView.backgroundColor = UIColor.init(red: CGFloat.random(in: 0..<257)/257, green: CGFloat.random(in: 0..<257)/257, blue: CGFloat.random(in: 0..<257)/257, alpha: 1)
        
        imageView = UIImageView(frame: frame)
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .scaleAspectFill
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView!)
        imageView?.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1).isActive = true
        imageView?.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1).isActive = true
    }
    
    func loadImage(_ photo: Photo) {
        self.imageView.image = nil
        
        if photo.imageData != nil {
            performUIUpdatesOnMain {
                self.imageView.image = UIImage(data: photo.imageData!)
            }
        } else {
            guard let imageURL = photo.imageURL, !(photo.imageURL?.isEmpty)! else {
                return
            }
            URLSession.shared.dataTask(with: URL(string: imageURL)!) { (data, response, error) in
                guard error == nil else {
                    return
                }
                performUIUpdatesOnMain {
                    self.imageView.image = UIImage(data: data!)
                }
            }
            .resume()
        }
    }
    
    func getImageData(_ photo: Photo) -> Data {
        let imageURL = URL(string: photo.imageURL!)
        let imageData = try? Data(contentsOf: imageURL!)
        return imageData!
    }
    
}
