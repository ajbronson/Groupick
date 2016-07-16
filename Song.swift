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
    private let kPreviouslyPlayed = "previouslyPlayed"
    private let kAddedBy = "addedBy"
    
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
        self.previouslyPlayed = false
        self.addedBy = UserController.getUser()
    }
    
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        guard let entity = NSEntityDescription.entityForName("Song", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        guard let timestamp = record.creationDate,
            let title = record[kTitle] as? String,
            let artist = record[kArtist] as? String,
            let trackID = record[kTrackID] as? String,
            let previouslyPlayed = record[kPreviouslyPlayed] as? Bool,
            let playlistReference = record[kPlaylist] as? CKReference,
            let addedByReference = record[kAddedBy] as? CKReference else { return nil }
        
        self.dateCreated = timestamp
        self.title = title
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        self.artist = artist
        self.trackID = trackID
        if let playlist = PlaylistController.sharedController.playlistWithID(playlistReference.recordID.recordName) {
            self.playlist = playlist
        }
        self.previouslyPlayed = previouslyPlayed
        if let imageURL = record[kImage] as? CKAsset {
           self.image = NSData(contentsOfURL: imageURL.fileURL)
        }
        self.changeToken = record.recordChangeTag
        self.addedBy = UserController.userWithID(addedByReference.recordID)
    }
    
    var cloudKitRecord: CKRecord? {
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[kTitle] = title
        record[kArtist] = artist
        record[kTrackID] = trackID
        record[kDateCreated] = dateCreated
        record[kPreviouslyPlayed] = previouslyPlayed
        if let temporaryPhotoURL = temporaryPhotoURL {
            record[kImage] = CKAsset(fileURL: temporaryPhotoURL)
        }
        
        guard let playlistRecordID = playlist.cloudKitRecord  else { fatalError("Song does not have a Playlist relationship") }
        record[kPlaylist] = CKReference(record: playlistRecordID, action: .DeleteSelf)
        
        if let addedBy = addedBy {
            guard let userRecordID = addedBy.cloudKitRecord  else { fatalError("Song does not have a Added By relationship") }
            record[kAddedBy] = CKReference(record: userRecordID, action: .DeleteSelf)
        }
        
        return record
    }
    
    lazy var temporaryPhotoURL: NSURL? = {
        guard let image = self.image else { return nil }
        // must write to temporary directory to be able to pass image url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        
        //set the UUID to a unique Identifier
        
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(self.id).URLByAppendingPathExtension("jpg")
        
        image.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
}

