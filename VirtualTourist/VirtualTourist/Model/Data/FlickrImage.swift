//
//  FlickrImage.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/6/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import Foundation

struct FlickrImage: Codable {
    
    let id: String
    let secret: String
    let server: String
    let farm: Int
    
    enum CodingKeys: String, CodingKey {
        case id, secret, server, farm
    }
    
    func photoURL() -> String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
    }
    
}
