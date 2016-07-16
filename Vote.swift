//
//  Vote.swift
//  Groupic
//
//  Created by AJ Bronson on 6/20/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class Vote: NSManagedObject, CloudKitManagedObject {
    
    private let kDateCreated = "dateCreated"
    private let kCreator = "creator"
    private let kVote = "vote"
    private let kSong = "song"
    private let kPlaylistID = "playlist"
    
    var recordType: String {
        return "Vote"
    }
    
    convenience init?(song: Song, creator: User, playlist: String, vote: Int, dateCreated: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Vote", inManagedObjectContext: context) else { fatalError("Core data failed to create entity") }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.song = song
        self.dateCreated = dateCreated
        self.creator = creator
        self.playlistRecordName = playlist
        self.id = NSUUID().UUIDString
        self.vote = vote
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let timestamp = record.creationDate,
            let songReference = record["song"] as? CKReference,
            let song = SongController.sharedController.songWithID(songReference.recordID.recordName),
            let creator = record["creator"] as? CKReference,
            let playlistRecordName = record["playlist"] as? String,
            let vote = record["vote"] as? Int else { return nil }
        guard let entity = NSEntityDescription.entityForName("Vote", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.dateCreated = timestamp
        self.song = song
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        self.playlistRecordName = playlistRecordName
        self.vote = vote
        if let user = UserController.userWithID(creator.recordID) {
            self.creator = user
        }
    }
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record[kPlaylistID] = playlistRecordName
        record[kVote] = vote
        record[kDateCreated] = dateCreated
        guard let songRecordID = song.cloudKitRecord  else { fatalError("Vote does not have a Song relationship") }
        record[kSong] = CKReference(record: songRecordID, action: .DeleteSelf)
        guard let userRecordID = creator.cloudKitRecord  else { fatalError("Vote does not have a Creator relationship") }
        record[kCreator] = CKReference(record: userRecordID, action: .DeleteSelf)
        
        return record
    }
    
}

