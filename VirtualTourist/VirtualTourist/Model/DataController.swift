//
//  DataController.swift
//  VirtualTourist
//
//  Created by Ashish Chatterjee on 5/6/19.
//  Copyright © 2019 Ashish Chatterjee. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
    func saveContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
}
