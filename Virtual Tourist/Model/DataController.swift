//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Travis Baker on 12/19/18.
//  Copyright © 2018 Travis Baker. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    static let shared = DataController()
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "VirtualTourist")
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func load() {
        persistentContainer.loadPersistentStores { (storeDescriptions, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            // perform any other setup.
        }
    }
}
