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
            print("api responded!")
            guard error == nil, let photosData = photosData else {
                completion([], error!)
                return
            }
            let nextPage = photosData.page == photosData.pages ? 1 : Int(photosData.page) + 1
            print("next page should be: \(nextPage)")
            print("current page is: \(photosData.page)")
            print("Number of pages is: \(photosData.pages)")
            self.resultsNextPage = Int16(nextPage)
            try? self.managedObjectContext?.save()
            completion(photosData.photo, nil)
        }
    }
    
    func deleteAllImages() {
        // if no photos, don't delete anything
        if self.photos?.count == 0 {
            return
        }
        DataController.shared.persistentContainer.performBackgroundTask({ (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
            let deleteRequest: NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
            deleteRequest.predicate = NSPredicate(format: "pin == %@", context.object(with: self.objectID))
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            if let batchResult = try? context.execute(batchDeleteRequest) as? NSBatchDeleteResult, let deletedIds = batchResult?.result as? [NSManagedObjectID] {
                if context.hasChanges {
                    try? context.save()
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedIds], into: [DataController.shared.viewContext])
                }
            }
        })
    }
    
    func fetchAllImages() {
        deleteAllImages()
        DispatchQueue.global(qos: .background).async {
            self.getImages(completion: { (photos, error) in
                print("got images")
                if let error = error {
                    // TODO: Show user some errror
                    print("There was a problem")
                    print(error)
                    return
                }
                
                for photoData in photos {
                    DataController.shared.persistentContainer.performBackgroundTask({ (context) in
                        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
                        let contextPin = context.object(with: self.objectID) as? Pin
                        print(photoData.id)
                        
                        let photo = Photo(context: context)
//                        photo.pin = contextPin
                        photo.setImageData(photoData)
                        contextPin?.addToPhotos(photo)
                        try? context.save()
                        try? photo.fetchImage()
                        try? context.save()
                    })
                }
            })
        }
    }
}
