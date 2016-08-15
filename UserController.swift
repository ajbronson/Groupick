//
//  UserController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class UserController {
    
    static let keyLoggedInUser = "login"
    
    static func saveUser(user: User) {
        NSUserDefaults.standardUserDefaults().setObject(user.dictionaryCopy, forKey: keyLoggedInUser)
        if let userRecord = user.cloudKitRecord {
            CloudKitManager.sharedManager.saveRecord(userRecord, completion: { (record, error) in
                if let error = error {
                    print("Error saving user - \(error.localizedDescription)... trying again...")
                    self.saveUser(user)
                }
            })
        }
    }
    
    
    static func getUserID() -> String {
        guard let loggedInUser = NSUserDefaults.standardUserDefaults().objectForKey(keyLoggedInUser) as? [String : AnyObject],
            let id = loggedInUser[kID] as? String else { return "" }
        return id
    }
    
    static func getUser() -> User? {
        guard let loggedInUser = NSUserDefaults.standardUserDefaults().objectForKey(keyLoggedInUser) as? [String : AnyObject],
            let id = loggedInUser[kID] as? String,
            let firstName = loggedInUser[kFirst] as? String,
            let lastName = loggedInUser[kLast] as? String else { return nil }
        if let ckid = loggedInUser[kCloudKitRecordName] as? String {
            return User(firstName: firstName, lastName: lastName, id: id, cloudKitRecordName: ckid)
        } else {
            return User(firstName: firstName, lastName: lastName, id: id, cloudKitRecordName: nil)
        }
        
    }
    
    static func removeUser() {
        NSUserDefaults.standardUserDefaults().setObject("", forKey: keyLoggedInUser)
    }
    
    static func userWithID(id: CKRecordID) -> User? {
        let request = NSFetchRequest(entityName: "User")
        let predicate = NSPredicate(format: "id == %@", argumentArray: [id.recordName])
        request.predicate = predicate
        do {
            let users = try Stack.sharedStack.managedObjectContext.executeFetchRequest(request) as? [User]
            if let user = users?.first {
                return user
            } else {
                return nil
            }
            
        } catch {
            return nil
        }
    }
}


