//
//  Song.swift
//  Groupic
//
//  Created by AJ Bronson on 6/27/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class Song: NSManagedObject, CloudKitManagedObject {
    
    private let kTitle = "title"
    private let kArtist = "artist"
    private let kTrackID = "trackID"
    private let kImage = "image"
    private let kPlaylist = "playlist"
    private let kDateCreated = "dateCreated"
    
    var recordType: String {
        return "Song"
    }
    
    convenience init(playlist: Playlist, title: String, artist: String, trackID: String, image: NSData?, dateCreated: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Song", inManagedObjectContext: context) else { fatalError("Core data failed to create entity") }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.title = title
        self.dateCreated = dateCreated
        self.artist = artist
        self.id = NSUUID().UUIDString
        self.playlist = playlist
        self.image = image
        self.trackID = trackID
    }
    
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let timestamp = record.creationDate,
            let title = record["title"] as? String,
            let artist = record["artist"] as? String,
            let trackID = record["trackID"] as? String,
            let image = record["image"] as? NSData,
            let playlist = record["playlist"] as? Playlist else { return nil }
        guard let entity = NSEntityDescription.entityForName("Playlist", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.dateCreated = timestamp
        self.title = title
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        self.artist = artist
        self.trackID = trackID
        self.playlist = playlist
        self.image = image
    }
    
    var cloudKitRecord: CKRecord? {
        guard let id = id else { return nil }
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[kTitle] = title
        record[kArtist] = artist
        record[kTrackID] = trackID
        record[kDateCreated] = dateCreated
        if let temporaryPhotoURL = temporaryPhotoURL {
            record[kImage] = CKAsset(fileURL: temporaryPhotoURL)
        }
        
        guard let playlistRecordID = playlist.cloudKitRecord  else { fatalError("Vote does not have a Creator relationship") }
        record[kPlaylist] = CKReference(record: playlistRecordID, action: .DeleteSelf)
        
        return record
    }
    
    lazy var temporaryPhotoURL: NSURL? = {
        guard let id = self.id, image = self.image else { return nil }
        // must write to temporary directory to be able to pass image url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        
        //set the UUID to a unique Identifier
        
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(id).URLByAppendingPathExtension("jpg")
        
        image.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
}

