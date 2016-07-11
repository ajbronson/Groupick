//
//  PlaylistController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

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
    }
    
    func createPlaylist(name: String, isPublic: Bool, passcode: String?) {
        if let user = UserController.getUser() {
            let playlist = Playlist(name: name, creator: user, isPublic: isPublic, passcode: passcode)
            save()
            
            if let playlist = playlist, playlistRecord = playlist.cloudKitRecord {
                
                CloudKitManager.sharedManager.saveRecord(playlistRecord, completion: { (record, error) in
                    if let record = record {
                        playlist.update(record)
                    } else if let error = error {
                        print("Error saving New Playlist - \(error.localizedDescription)")
                    }
                    self.createUserPlaylistCKRecord(playlist)
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
        
        save()
        if let newPlaylist = newPlaylist {
            addSubscriptionToPlaylistSongs(newPlaylist, completion: { (success, error) in
                if let error = error {
                    print("Unable to save song subscription: \(error.localizedDescription)")
                }
            })
            if let ckRecord = newPlaylist.cloudKitRecord {
                let predicate = NSPredicate(format: "playlist == %@", argumentArray: [ckRecord.recordID])
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
                            //TODO: need to subscribe to these songs deletions, and their votes
                            if let songCKRecord = song.cloudKitRecord {
                                let predicate = NSPredicate(format: "song == %@", argumentArray: [songCKRecord.recordID])
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
                    self.createUserPlaylistCKRecord(newPlaylist)
                    self.subscribeToPlaylistDeletion(newPlaylist)
                })
            }
        }
    }
    
    func subscribeToPlaylistDeletion(playlist: Playlist) {
        let predicate = NSPredicate(format: "id == %@", argumentArray: [playlist.cloudKitRecordID.recordName])
        CloudKitManager.sharedManager.subscribe("Playlist", predicate: predicate, identifier: "Delete_Playlist_\(playlist.cloudKitRecordID.recordName)", contentAvailable: true, options: .FiresOnRecordDeletion) { (subscription, error) in
            if let error = error {
                print("Error saving Playlist Deletion Subscription - \(error.localizedDescription)")
            }
        }
    }
    
    func createUserPlaylistCKRecord(playlist: Playlist) {
        if let userCKRID = UserController.getUser()?.cloudKitRecordID {
            let id = NSUUID().UUIDString
            let recordID = CKRecordID(recordName: id)
            let record = CKRecord(recordType: "UserPlaylist", recordID: recordID)
            let playlistReference = CKReference(recordID: playlist.cloudKitRecordID, action: .DeleteSelf)
            let userReference = CKReference(recordID: userCKRID, action: .DeleteSelf)
            record["playlist"] = playlistReference
            record["user"] = userReference
            CloudKitManager.sharedManager.saveRecord(record, completion: { (record, error) in
                if let error = error {
                    print("error saving user playlist object to CloudKit - \(error.localizedDescription)")
                }
            })
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
    
    func playlistWithID(id: String) -> Playlist? {
        let predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        let request = NSFetchRequest(entityName: "Playlist")
        request.predicate = predicate
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(request) as? [Playlist]) ?? nil
        return result?.first
    }
    
    
    func save() {
        do {
            try moc.save()
        } catch let error as NSError {
            print("Error saving object - \(error)")
        }
    }
    
    func addSubscriptionToPlaylistSongs(playlist: Playlist, completion: ((success: Bool, error: NSError?) -> Void)?) {
        let predicate = NSPredicate(format: "playlist == %@", argumentArray: [playlist.cloudKitRecordID])
        
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.song.rawValue, predicate: predicate, identifier: playlist.cloudKitRecordID.recordName, alertBody: "Playlist Received A New Song! 😎", contentAvailable: true, desiredKeys: nil, options: .FiresOnRecordCreation) { (subscription, error) in
            if let completion = completion {
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
}



