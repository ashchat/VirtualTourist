//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/6/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import Foundation

class FlickrClient {
    
    enum Endpoints {
        
        static let base = "https://api.flickr.com/services/rest/"
        
        case search(Double,Double,Int)
        
        var stringValue: String {
            switch self {
            case .search(let lat, let lon, let page): return Endpoints.base + "?method=flickr.photos.search&api_key=\(AppDelegate.apiKey)&lat=\(lat)&lon=\(lon)&radius=10&radius_units=km&format=json&nojsoncallback=1&per_page=21&page=\(page)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
    }
    
    // GET Task for Flickr Images
    // Using flickr.photos.search method as this does not require an Auth token
    // Seems to be the best option for project requirements
    
    class func taskForGETFlickrImages(lat: Double, long: Double, page: Int, completion: @escaping (GetFlickrImagesResponse?, Error?) -> Void) {
        var request = URLRequest(url: Endpoints.search(lat, long, page).url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                performUIUpdatesOnMain {
                    completion(nil, error)
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(GetFlickrImagesResponse.self, from: data)
                performUIUpdatesOnMain {
                    completion(responseObject, nil)
                }
            } catch {
                performUIUpdatesOnMain {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
}
