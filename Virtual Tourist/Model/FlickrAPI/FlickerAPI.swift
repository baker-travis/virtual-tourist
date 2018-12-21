//
//  FlickerAPI.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation

struct FlickerAPI {
    static let ApiKey = "6d753cab028a9576611999c6b3f88e3f"
    static let ApiSecret = "94587e68e8ac244e"
    
    enum Errors: LocalizedError {
        case noData
        case unknownError
    }
    
    enum Endpoints {
        case searchImagesByLatLong(lat: Double, long: Double, page: Int)
        case getImageById(farmId: String, serverId: String, imageId: String, imageSecret: String)
        
        var url: URL {
            switch self {
            case let .getImageById(farmId, serverId, imageId, imageSecret):
                return URL(string: "https://farm\(farmId).staticflickr.com/\(serverId)/\(imageId)_\(imageSecret)_m.jpg")!
            case let .searchImagesByLatLong(lat, long, page):
                var components = URLComponents(string: "https://api.flickr.com/services/rest/")!
                var queryItems: [URLQueryItem] = []
                queryItems.append(URLQueryItem(name: "method", value: "flickr.photos.search"))
                queryItems.append(URLQueryItem(name: "api_key", value: ApiKey))
                queryItems.append(URLQueryItem(name: "format", value: "json"))
                queryItems.append(URLQueryItem(name: "nojsoncallback", value: "1"))
                queryItems.append(URLQueryItem(name: "per_page", value: "50"))
                queryItems.append(URLQueryItem(name: "lat", value: "\(lat)"))
                queryItems.append(URLQueryItem(name: "lon", value: "\(long)"))
                queryItems.append(URLQueryItem(name: "radius", value: "20"))
                queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
                components.queryItems = queryItems
                return components.url!
            }
        }
    }
    
    static func getPicturesByLatAndLong(latitude: Double, longitude: Double, page: Int = 1, completion: @escaping (PhotosMetaData?, Error?) -> Void) {
        let url = Endpoints.searchImagesByLatLong(lat: latitude, long: longitude, page: page).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, Errors.noData)
                return
            }
            
            if let response = try? JSONDecoder().decode(PhotosSearchResponse.self, from: data) {
                completion(response.photos, nil)
                return
            } else {
                print(String(data: data, encoding: .utf8)!)
                completion(nil, Errors.unknownError)
            }
        }
        
        task.resume()
    }
}
