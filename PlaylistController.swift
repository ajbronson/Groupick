//
//  PlaylistController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData

class PlaylistController {
    
    static let sharedController = PlaylistController()
    let moc = Stack.sharedStack.managedObjectContext
    
    
    let fetchedResultsController: NSFetchedResultsController
    
    var playlists: [Playlist] = []
    
    init() {
        let request = NSFetchRequest(entityName: "Playlist")
        let sortDescriptor1 = NSSortDescriptor(key: "dateCreated", ascending: true)
        request.sortDescriptors = [sortDescriptor1]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        _ = try? fetchedResultsController.performFetch()
        //fullSync()
    }
    
    func createPlaylist(name: String, isPublic: Bool, passcode: String?) {
        if let user = UserController.getUser() {
            let playlist = Playlist(name: name, creator: user, isPublic: isPublic, passcode: passcode)
            save()
            
            if let playlist = playlist, playlistRecord = playlist.cloudKitRecord {
                CloudKitManager.sharedManager.saveRecord(playlistRecord, completion: { (record, error) in
                    if let record = record {
                        playlist.update(record)
                    }
                })
                addSubscriptionToPlaylistSongs(playlist, completion: { (success, error) in
                    if let error = error {
                        print("Unable to save song subscription: \(error.localizedDescription)")
                    }
                })
            }
        }
    }
    
    func joinPlaylist(playlist: TempPlaylist) {
        let newPlaylist = Playlist(record: playlist.ckRecord)

        
        //TODO: Join followers, save to cloud
        save()
        if let newPlaylist = newPlaylist {
            addSubscriptionToPlaylistSongs(newPlaylist, completion: { (success, error) in
                if let error = error {
                    print("Unable to save song subscription: \(error.localizedDescription)")
                }
            })
            if let ckRecord = newPlaylist.cloudKitRecord {
                let predicate = NSPredicate(format: "playlist == %@", argumentArray: [ckRecord.recordID.recordName])
                CloudKitManager.sharedManager.fetchRecordsWithType("Song", predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
                    if let records = records {
                        var songs = [Song]()
                        for record in records {
                            let newSong = Song(record: record)
                            if let newSong = newSong {
                                songs.append(newSong)
                                PlaylistController.sharedController.save()
                            }
                        }
                        for song in songs {
                            if let songCKRecord = song.cloudKitRecord {
                                let predicate = NSPredicate(format: "song == %@", argumentArray: [songCKRecord.recordID.recordName])
                                CloudKitManager.sharedManager.fetchRecordsWithType("Vote", predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
                                    if let records = records {
                                        for record in records {
                                            let _ = Vote(record: record)
                                            PlaylistController.sharedController.save()
                                        }
                                    }
                                })
                            }
                        }
                    }
                })
            }
        }
    }
    
    func nowPlaying(playlist: Playlist, song: Song) {
        playlist.nowPlaying = song.id
        save()
        
    }
    
    func changePasscode(playlist: Playlist, newCode: String) {
        playlist.passcode = newCode
        save()
    }
    
    func deletePlaylist(playlist: Playlist) {
        if playlist.creator.id == UserController.getUserID() {
            
            if let playlistRecord = playlist.cloudKitRecord {
                CloudKitManager.sharedManager.deleteRecordWithID(playlistRecord.recordID, completion: { (recordID, error) in
                    if let error = error {
                        print("Error deleting playlist - \(error.localizedDescription)")
                    }
                })
            }
            playlist.managedObjectContext?.deleteObject(playlist)
            
        } else if let user = UserController.getUser() {
            //TODO: Figure out how to remove user from playlist follower, also remove playlist from user following
            //let index = playlist.followers?.indexOfObject(user)
            //playlist.followers.
            playlist.managedObjectContext?.deleteObject(playlist)
        }
        save()
    }
    
    
    func save() {
        do {
            try moc.save()
        } catch let error as NSError {
            print("Error saving object - \(error)")
        }
    }
    
    /*
     func fullSync() {
     fetchNewRecords("Playlist") {
     self.fetchNewRecords("Songs", completion: nil)
     }
     }
     
     
     func fetchNewRecords(type: String, completion: (() -> Void)?) {
     
     let referencesToExclude = syncedRecords(type).flatMap({$0.cloudKitReference})
     var predicate = NSPredicate(format: "NOT (recordID IN %@)", argumentArray: [referencesToExclude])
     
     if referencesToExclude.isEmpty {
     predicate = NSPredicate(value: true)
     }
     
     CloudKitManager.sharedManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
     
     if type == "Playlist" {
     _ = Playlist(record: record)
     self.save()
     } else if type == "Song" {
     _ = Song(record: record)
     self.save()
     }
     }) { (records, error) in
     if error != nil {
     print("Oh no!")
     }
     
     if let completion = completion {
     completion()
     }
     }
     }
     */
    
    func syncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "changeToken != nil")
        fetchRequest.predicate = predicate
        let response = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        return response
    }
    
    func unsyncedRecords(type: String) -> [CloudKitManagedObject] {
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "changeToken == nil")
        fetchRequest.predicate = predicate
        let response = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        return response
    }
    
    func addSubscriptionToPlaylistSongs(playlist: Playlist, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        let predicate = NSPredicate(format: "playlist == %@", argumentArray: [playlist.cloudKitRecordID])
        
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.song.rawValue, predicate: predicate, identifier: playlist.cloudKitRecordID.recordName, alertBody: "Playlist Received A New Song! 😎", contentAvailable: true, desiredKeys: ["dateCreated", "title", "artist", "trackID", "playlist"], options: .FiresOnRecordCreation) { (subscription, error) in
            if let completion = completion {
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
}

//["dateCreated", "title", "artist", "trackID", "previouslyPlayed", "addedBy", "image"]


