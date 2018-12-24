//
//  Pin+Coordinates.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

extension Pin {
    var coordinates: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        set(newCoordinates) {
            self.latitude = newCoordinates.latitude
            self.longitude = newCoordinates.longitude
        }
    }
    
    func getImages(completion: @escaping ([PhotoData], Error?) -> Void) {
        FlickerAPI.getPicturesByLatAndLong(latitude: self.latitude, longitude: self.longitude, page: Int(self.resultsNextPage)) { (photosData, error) in
            guard error == nil, let photosData = photosData else {
                completion([], error!)
                return
            }
            let nextPage = photosData.page == photosData.pages ? 1 : Int(photosData.page) + 1
            self.resultsNextPage = Int16(nextPage)
            try? self.managedObjectContext?.save()
            completion(photosData.photo, nil)
        }
    }
    
    func deleteAllImages(completion: @escaping () -> Void) {
        // if no photos, don't delete anything
        if self.photos?.count == 0 {
            completion()
            return
        }

        DataController.shared.persistentContainer.performBackgroundTask({ (context) in
            if let photos = self.photos {
                let copyOfPhotos = photos.copy() as! NSSet
                copyOfPhotos.forEach({ (photo) in
                    guard let photo = photo as? Photo else { return }
                    
                    context.delete(context.object(with: photo.objectID))
//                    DataController.shared.viewContext.delete(photo)
                })
//                try? DataController.shared.viewContext.save()
                try? context.save()
            }
            completion()
        })
    }
    
    func fetchAllImages(completion: (() -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.getImages(completion: { (photos, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
                }
                
                DataController.shared.persistentContainer.performBackgroundTask({ (context) in
                    var savedPhotos: [Photo] = []
                    for photoData in photos {
                        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
                        let contextPin = context.object(with: self.objectID) as? Pin
                        
                        let photo = Photo(context: context)
                        photo.setImageData(photoData)
                        contextPin?.addToPhotos(photo)
                        try? context.save()
                        savedPhotos.append(photo)
                    }
                    // Call completion handler here to perform actual fetching of image in the background.
                    DispatchQueue.main.async {
                        completion?()
                    }
                    savedPhotos.forEach({ (photo) in
                        try? photo.fetchImage()
                        try? context.save()
                    })
                })
            })
        }
    }
}
