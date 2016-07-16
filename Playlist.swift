//
//  Playlist.swift
//  Groupic
//
//  Created by AJ Bronson on 6/20/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

public let kDateCreated = "dateCreated"
public let kCreator = "creator"
public let kPasscode = "passcode"
public let kIsPublic = "isPublic"
public let kName = "name"
public let kNowPlaying = "nowPlaying"

class Playlist: NSManagedObject, CloudKitManagedObject {
    
    var recordType: String {
        return "Playlist"
    }
    
    convenience init?(name: String, creator: User, isPublic: Bool, passcode: String?, dateCreated: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Playlist", inManagedObjectContext: context) else { fatalError("Core data failed to create entity") }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.name = name
        self.isPublic = isPublic
        self.passcode = passcode
        self.dateCreated = dateCreated
        self.creator = creator
        self.id = NSUUID().UUIDString
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let timestamp = record.creationDate,
            let creator = record[kCreator] as? CKReference,
            let isPublic = record[kIsPublic] as? Bool,
            let name = record[kName] as? String else { return nil }
        guard let entity = NSEntityDescription.entityForName("Playlist", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.dateCreated = timestamp
        self.name = name
        self.isPublic = isPublic
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        if let user = UserController.userWithID(creator.recordID) {
            self.creator = user
        }
        if let nowPlaying = record[kNowPlaying] as? String {
            self.nowPlaying = nowPlaying
        }
    }
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[kDateCreated] = dateCreated
        record[kName] = name
        record[kPasscode] = passcode
        record[kIsPublic] = isPublic
        record[kID] = id
        record[kNowPlaying] = nowPlaying
        guard let userRecordID = creator.cloudKitRecord  else { fatalError("Playlist does not have a Creator relationship") }
        record[kCreator] = CKReference(record: userRecordID, action: .DeleteSelf)
        
        return record
    }
    
    
}

