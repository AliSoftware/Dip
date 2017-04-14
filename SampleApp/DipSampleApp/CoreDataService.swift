//
//  CoreDataService.swift
//  Routes
//
//  Created by Leandro Perez on 2/3/17.
//  Copyright © 2017 Leandro Perez. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol CoreDataService{
    var context : NSManagedObjectContext {get}
}

class CoreDataServiceImpl : CoreDataService {
    
    let modelName = "Routes"
    
    @available(iOS 10.0, *)
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores { (storeDescription, error) in
            print("CoreData: Initialized \(storeDescription)")
            guard error == nil else {
                print("CoreData: Unresolved error \(String(describing: error))")
                return
            }
        }
        return container
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        do {
            return try NSPersistentStoreCoordinator.coordinator(name: self.modelName)
        } catch {
            print("CoreData: Unresolved error \(error)")
        }
        return nil
    }()
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: Public methods
    
    enum SaveStatus {
        case saved, rolledBack, hasNoChanges
    }
    
    var context: NSManagedObjectContext {
        get {
            if #available(iOS 10.0, *) {
                return persistentContainer.viewContext
            } else {
                return managedObjectContext
            }
        }
    }
    
    func save() -> SaveStatus {
        if context.hasChanges {
            do {
                try context.save()
                return .saved
            } catch {
                assert(false, "Unknown core data error")
                context.rollback()
                return .rolledBack
            }
        }
        return .hasNoChanges
    }
    
}

//Taken from https://gist.github.com/avdyushin/b67e4524edcfb1aec47605da1a4bea7a
/// NSPersistentStoreCoordinator extension
extension NSPersistentStoreCoordinator {
    
    /// NSPersistentStoreCoordinator error types
    public enum CoordinatorError: Error {
        /// .momd file not found
        case modelFileNotFound
        /// NSManagedObjectModel creation fail
        case modelCreationError
        /// Gettings document directory fail
        case storePathNotFound
    }
    
    /// Return NSPersistentStoreCoordinator object
    static func coordinator(name: String) throws -> NSPersistentStoreCoordinator? {
        
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            throw CoordinatorError.modelFileNotFound
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoordinatorError.modelCreationError
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            throw CoordinatorError.storePathNotFound
        }
        
        do {
            let url = documents.appendingPathComponent("\(name).sqlite")
            let options = [ NSMigratePersistentStoresAutomaticallyOption : true,
                            NSInferMappingModelAutomaticallyOption : true ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            throw error
        }
        
        return coordinator
    }
}



//MARK: - No lazy properties, it works.

////
////  CoreDataService.swift
////  Routes
////
////  Created by Leandro Perez on 2/3/17.
////  Copyright © 2017 Leandro Perez. All rights reserved.
////
//
//import Foundation
//import CoreData
//import UIKit
//
//protocol CoreDataService{
//    var context : NSManagedObjectContext {get}
//}
//
//class CoreDataServiceImpl : CoreDataService {
//    
//    enum SaveStatus {
//        case saved, rolledBack, hasNoChanges
//    }
//    
//    let modelName = "Routes"
//    
//    //iOS >= 10.0
//    var container : Any?
//    @available(iOS 10.0, *)
//    var persistentContainer: NSPersistentContainer{
//        get {
//            if container != nil{
//                return container as! NSPersistentContainer
//            }
//            else{
//                let theContainer = NSPersistentContainer(name: self.modelName)
//                theContainer.loadPersistentStores { (storeDescription, error) in
//                    print("CoreData: Initialized \(storeDescription)")
//                    guard error == nil else {
//                        print("CoreData: Unresolved error \(String(describing: error))")
//                        return
//                    }
//                }
//                container = theContainer
//                return theContainer
//            }
//    }}
//    
//    //iOS < 10.0
//    var persistentStoreCoordinator: NSPersistentStoreCoordinator!
//    var managedObjectContext: NSManagedObjectContext!
//    
//    init() throws {
//        if #available(iOS 10.0, *) {} else {
//            //iOS < 10.0
//            do {
//                persistentStoreCoordinator = try NSPersistentStoreCoordinator.coordinator(name: self.modelName)
//            } catch let error {
//                print("CoreData: Unresolved error \(error)")
//                throw error
//            }
//            
//            managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
//        }
//    }
//    
//    // MARK: - public
//    var context: NSManagedObjectContext {
//         get {
//            if #available(iOS 10.0, *) {
//                return persistentContainer.viewContext
//            } else {
//                return managedObjectContext
//            }
//        }
//    }
//    
//     func save() -> SaveStatus {
//        if context.hasChanges {
//            do {
//                try context.save()
//                return .saved
//            } catch {
//                assert(false, "Unknown core data error")
//                context.rollback()
//                return .rolledBack
//            }
//        }
//        return .hasNoChanges
//    }
//    
//}
//
////Taken from https://gist.github.com/avdyushin/b67e4524edcfb1aec47605da1a4bea7a
///// NSPersistentStoreCoordinator extension
//extension NSPersistentStoreCoordinator {
//    
//    /// NSPersistentStoreCoordinator error types
//    public enum CoordinatorError: Error {
//        /// .momd file not found
//        case modelFileNotFound
//        /// NSManagedObjectModel creation fail
//        case modelCreationError
//        /// Gettings document directory fail
//        case storePathNotFound
//    }
//    
//    /// Return NSPersistentStoreCoordinator object
//    static func coordinator(name: String) throws -> NSPersistentStoreCoordinator? {
//        
//        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
//            throw CoordinatorError.modelFileNotFound
//        }
//        
//        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
//            throw CoordinatorError.modelCreationError
//        }
//        
//        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
//        
//        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
//            throw CoordinatorError.storePathNotFound
//        }
//
//        do {
//            let url = documents.appendingPathComponent("\(name).sqlite")
//            let options = [ NSMigratePersistentStoresAutomaticallyOption : true,
//                            NSInferMappingModelAutomaticallyOption : true ]
//            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
//        } catch {
//            throw error
//        }
//        
//        return coordinator
//    }
//}
//
