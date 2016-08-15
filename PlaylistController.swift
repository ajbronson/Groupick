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
    
    var totalSubscriptions: Int = 0
    var playlists: [Playlist] = []
    var subscriptionCount = 0
    
    init() {
        let request = NSFetchRequest(entityName: "Playlist")
        let sortDescriptor1 = NSSortDescriptor(key: "dateCreated", ascending: true)
        request.sortDescriptors = [sortDescriptor1]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        _ = try? fetchedResultsController.performFetch()
        //TODO: Sometimes I need this - unsubscribeFromAll()
    }
    
    func setNumberOfSubscriptions() {
        numberOfSubscriptions { (totalSubscriptions) in
            if let totalSubscriptions = totalSubscriptions {
                self.totalSubscriptions = totalSubscriptions
            }
        }
    }
    
    func changeSubscriptionCount(by: Int) -> Int {
        totalSubscriptions = totalSubscriptions + by
        return totalSubscriptions
    }
    
    func createPlaylist(name: String, isPublic: Bool, passcode: String?) {
        if let user = UserController.getUser() {
            let playlist = Playlist(name: name, creator: user, isPublic: isPublic, passcode: passcode)
            save()
            
            if let playlist = playlist, playlistRecord = playlist.cloudKitRecord {
                savePlaylistCKRecord(playlistRecord, playlist: playlist)
            }
        }
    }
    
    func savePlaylistCKRecord(playlistRecord: CKRecord, playlist: Playlist) {
        CloudKitManager.sharedManager.saveRecord(playlistRecord, completion: { (record, error) in
            if let error = error {
                print("Error saving New Playlist - \(error.localizedDescription)... trying again...")
                self.savePlaylistCKRecord(playlistRecord, playlist: playlist)
            }
            self.createUserPlaylistCKRecord(playlist)
        })
    }
    
    func joinPlaylist(playlist: TempPlaylist) {
        let newPlaylist = Playlist(record: playlist.ckRecord)
        
        save()
        if let newPlaylist = newPlaylist {
            if let ckRecord = newPlaylist.cloudKitRecord {
                let predicate = NSPredicate(format: "playlist == %@", argumentArray: [ckRecord.recordID])
                fetchSongsFromCK(predicate, newPlaylist: newPlaylist)
            }
        }
    }
    
    func fetchSongsFromCK(predicate: NSPredicate, newPlaylist: Playlist) {
        CloudKitManager.sharedManager.fetchRecordsWithType(CloudKitManager.RecordTypes.song.rawValue, predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
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
                        let predicate = NSPredicate(format: "song == %@", argumentArray: [songCKRecord.recordID])
                        self.fetchVotesFromCK(predicate)
                    }
                }
            } else if let error = error {
                print("Error fetching songs from joined playlist - \(error.localizedDescription)... trying again...")
                self.fetchSongsFromCK(predicate, newPlaylist: newPlaylist)
            }
            self.createUserPlaylistCKRecord(newPlaylist)
        })

    }
    
    func fetchVotesFromCK(predicate: NSPredicate) {
        CloudKitManager.sharedManager.fetchRecordsWithType(CloudKitManager.RecordTypes.vote.rawValue, predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
            if let records = records {
                for record in records {
                    let _ = Vote(record: record)
                    PlaylistController.sharedController.save()
                }
            } else if let error = error {
                print("Error fetching votes from joined playlist's songs \(error.localizedDescription)... trying again...")
                self.fetchVotesFromCK(predicate)
            }
        })
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
            saveUserPlaylistCK(record, playlist: playlist)
        }
    }
    
    func saveUserPlaylistCK(upRecord: CKRecord, playlist: Playlist) {
        CloudKitManager.sharedManager.saveRecord(upRecord, completion: { (record, error) in
            if let error = error {
                print("error saving user playlist object to CloudKit - \(error.localizedDescription)... trying again...")
                self.saveUserPlaylistCK(upRecord, playlist: playlist)
            } else {
               self.addSubscriptions(playlist)
            }
        })
    }
    
    func nowPlaying(playlist: Playlist, song: Song?) {
        if let song = song {
           playlist.nowPlaying = song.id
        } else {
            playlist.nowPlaying = nil
        }
        save()
        if let record = playlist.cloudKitRecord {
            modifyNowPlayingCK(record)
        }
    }
    
    func modifyNowPlayingCK(playlistRecord: CKRecord) {
        CloudKitManager.sharedManager.modifyRecords([playlistRecord], perRecordCompletion: nil, completion: { (records, error) in
            if let error = error {
                print("Error fetching playlist to update now playing - \(error.localizedDescription)")
                self.modifyNowPlayingCK(playlistRecord)
            }
        })
    }
    
    func changePasscode(playlist: Playlist, newCode: String) {
        playlist.passcode = newCode
        save()
    }
    
    func deletePlaylist(playlist: Playlist) {
        if playlist.creator.id == UserController.getUserID() {
            
            if let playlistRecord = playlist.cloudKitRecord {
                deletePlaylistFromCK(playlistRecord.recordID)
            }
        }
        
        else if let user = UserController.getUser() {
            let predicate = NSPredicate(format: "user == %@ && playlist == %@", argumentArray: [user.cloudKitRecordID, playlist.cloudKitRecordID])
            removeUserPlaylistCKRecord(predicate)
        }
        unbsubscribeFromPlaylist(playlist.cloudKitRecordID.recordName)
        playlist.managedObjectContext?.deleteObject(playlist)
        save()
    }
    
    func deletePlaylistFromCK(playlistRecordID: CKRecordID) {
        CloudKitManager.sharedManager.deleteRecordWithID(playlistRecordID, completion: { (recordID, error) in
            if let error = error {
                print("Error deleting playlist - \(error.localizedDescription)... trying again...")
                self.deletePlaylistFromCK(playlistRecordID)
            }
        })
    }
    
    func removePlaylistFromCoreData(playlist: Playlist) {
        unbsubscribeFromPlaylist(playlist.cloudKitRecordID.recordName)
        playlist.managedObjectContext?.deleteObject(playlist)
        save()
    }
    
    func removeUserPlaylistCKRecord(predicate: NSPredicate) {
        CloudKitManager.sharedManager.fetchRecordsWithType(CloudKitManager.RecordTypes.userPlaylist.rawValue, predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
            if let records = records {
                let recordIDs = records.flatMap({$0.recordID})
                if let recordID = recordIDs.first {
                    CloudKitManager.sharedManager.deleteRecordWithID(recordID, completion: { (recordID, error) in
                        if let error = error {
                            print("error deleting userPlaylist record from CK - \(error.localizedDescription)... trying again...")
                            self.removeUserPlaylistCKRecord(predicate)
                        }
                    })
                }
            }
        })
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
    
    
    func addSubscriptions(playlist: Playlist) {
        addSubscriptionToSongs(playlist.cloudKitRecordID)
    }
    
    func addSubscriptionToSongs(playlistRecordID: CKRecordID) {
        let predicate = NSPredicate(format: "playlist == %@", argumentArray: [playlistRecordID])
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.song.rawValue, predicate: predicate, identifier: "Song_\(playlistRecordID.recordName)", alertBody: nil, contentAvailable: true, desiredKeys: ["previouslyPlayed"], options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion]) { (subscription, error) in
            if let error = error {
                print("Error Saving Songs Subscription - \(error.localizedDescription)... trying again...")
                self.addSubscriptionToSongs(playlistRecordID)
            } else {
                self.changeSubscriptionCount(1)
            }
            self.addSubscribtionToPlaylist(playlistRecordID)
        }
    }
    
    func addSubscribtionToPlaylist(playlistRecordID: CKRecordID) {
        let predicate = NSPredicate(format: "id == %@", argumentArray: [playlistRecordID.recordName])
        
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.playlist.rawValue, predicate: predicate, identifier: "Playlist_\(playlistRecordID.recordName)", alertBody: nil, contentAvailable: true, desiredKeys: [kNowPlaying], options: [.FiresOnRecordDeletion, .FiresOnRecordUpdate]) { (subscription, error) in
            if let error = error {
                print("Error Saving Playlist Subscription - \(error.localizedDescription)... trying again...")
                self.addSubscribtionToPlaylist(playlistRecordID)
            } else {
                self.changeSubscriptionCount(1)
            }
            self.addSubscriptionToVotes(playlistRecordID)
        }
    }
    
    func addSubscriptionToVotes(playlistRecordID: CKRecordID) {
        let predicate = NSPredicate(format: "playlist == %@", argumentArray: [playlistRecordID.recordName])
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.vote.rawValue, predicate: predicate, identifier: "Votes_\(playlistRecordID.recordName)", alertBody: nil, contentAvailable: true, desiredKeys: nil, options: [.FiresOnRecordCreation, .FiresOnRecordDeletion]) { (subscription, error) in
            if let error = error {
                print("Error Saving Vote Subscription - \(error.localizedDescription)... trying again...")
                self.addSubscriptionToVotes(playlistRecordID)
            } else {
                self.changeSubscriptionCount(1)
            }
            self.addSubscriptionToUserPlaylists(playlistRecordID)
        }
    }
    
    func addSubscriptionToUserPlaylists(playlistRecordID: CKRecordID) {
        let predicate = NSPredicate(format: "playlist == %@", argumentArray: [playlistRecordID])
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.userPlaylist.rawValue, predicate: predicate, identifier: "UserP_\(playlistRecordID.recordName)", alertBody: nil, contentAvailable: true, desiredKeys: ["playlist", "user"], options: [.FiresOnRecordDeletion]) { (subscription, error) in
            if let error = error {
                print("Error Saving UserPlaylist Subscription - \(error.localizedDescription)... trying again...")
                self.addSubscriptionToUserPlaylists(playlistRecordID)
            } else {
                self.changeSubscriptionCount(1)
            }
            self.numberOfSubscriptions({ (_) in})
        }
    }
    
    func unbsubscribeFromPlaylist(recordName: String) {
        CloudKitManager.sharedManager.fetchSubscriptions { (subscriptions, error) in
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    if subscription.subscriptionID == "UserP_\(recordName)" || subscription.subscriptionID == "Votes_\(recordName)" || subscription.subscriptionID == "Playlist_\(recordName)" || subscription.subscriptionID == "Song_\(recordName)" {
                        CloudKitManager.sharedManager.unsubscribe(subscription, completion: { (subscriptionID, error) in
                            if let error = error {
                                print("Error unsubscribing from Playlist's Subscriptions = \(error.localizedDescription)... trying again...")
                                self.unbsubscribeFromPlaylist(recordName)
                            } else {
                                self.changeSubscriptionCount(-1)
                            }
                            self.numberOfSubscriptions({ (_) in})
                        })
                    }
                }
            }
        }
    }
    
    func numberOfSubscriptions(completion: (totalSubscriptions: Int?) -> Void) {
        CloudKitManager.sharedManager.fetchSubscriptions { (subscriptions, error) in
            if let subscriptions = subscriptions {
                print("THERE ARE >>>>>>>>>>>>>>>>>>>> \(subscriptions.count) <<<<<<<<<<<<<<< SUBSCRIPTIONS")
                completion(totalSubscriptions: subscriptions.count)
            } else {
                completion(totalSubscriptions: nil)
            }
        }
    }
    
    func unsubscribeFromAll() {
        CloudKitManager.sharedManager.fetchSubscriptions { (subscriptions, error) in
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    CloudKitManager.sharedManager.unsubscribe(subscription, completion: { (subscriptionID, error) in
                        if let error = error {
                            print("ERROR UNSUBSCRIBING!!! - \(error.localizedDescription)")
                        } else {
                            print("SUCCESS UNSUBSCRIBING! \(self.subscriptionCount)")
                            self.totalSubscriptions = self.subscriptionCount
                        }
                    })
                }
            }
        }
    }
}



