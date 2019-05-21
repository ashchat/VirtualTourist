//
//  LocationsFeedVCLabel.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/20/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import UIKit

class LocationsFeedVCLabel: UILabel {
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setLabelUI(false)
    }
    
    func setLabelUI(_ isEditing: Bool) {
        switch isEditing {
        case true:
            self.backgroundColor = UIColor.red
            self.text = "TAP BIN TO DELETE SELECTED PHOTOS"
        case false:
            self.backgroundColor = UIColor.udacity
            self.text = "TAP REFRESH TO LOAD MORE IMAGES"
        }
    }

}
