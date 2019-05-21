//
//  GetFlickrImagesResponse.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/6/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import Foundation

struct GetFlickrImagesResponse: Codable {
    
    let photos : photosResponse
    
    enum CodingKeys: String, CodingKey {
        case photos
    }
    
}

struct photosResponse: Codable {
    
    let totalString: String
    let images: [FlickrImage]
    let page: Int
    let pages: Int
    
    enum CodingKeys: String, CodingKey {
        case totalString = "total"
        case page,pages
        case images = "photo"
    }

    func total() -> Int {
        return Int(totalString) ?? 0
    }
    
}
