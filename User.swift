//
//  User.swift
//  Groupic
//
//  Created by AJ Bronson on 6/20/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

public let kFirst = "first"
public let kLast = "last"
public let kID = "id"
public let kCloudKitRecordName = "cloudKitRecordName"

class User: NSManagedObject, CloudKitManagedObject {
    
    var recordType: String {
        return "User"
    }
    
    convenience init(firstName: String, lastName: String, id: String = NSUUID().UUIDString, cloudKitRecordName: String?, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: context) else { fatalError("Core data failed to create entity") }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.firstName = firstName
        self.lastName = lastName
        self.id = id
        self.cloudKitRecordName = cloudKitRecordName
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let firstName = record[kFirst] as? String,
            let lastName = record[kLast] as? String else { return nil }
        guard let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.firstName = firstName
        self.lastName = lastName
        self.id = record.recordID.recordName
        if let ckid = record[kCloudKitRecordName] as? String {
           self.cloudKitRecordName = ckid
        } else {
            self.cloudKitRecordName = nil
        }
        
        self.changeToken = record.recordChangeTag
        
    }
    
    var dictionaryCopy: [String: AnyObject] {
        guard let firstName = firstName,
            let lastName = lastName else { return [:] }
        if let ckid = cloudKitRecordName {
            return [
                kFirst:firstName,
                kLast:lastName,
                kID:id,
                kCloudKitRecordName:ckid
            ]
        } else {
            return [
                kFirst:firstName,
                kLast:lastName,
                kID:id,
            ]
        }

    }
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[kLast] = lastName
        record[kFirst] = firstName
        record[kCloudKitRecordName] = cloudKitRecordName
        
        return record
    }
    
}


