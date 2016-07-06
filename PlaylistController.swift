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
            let _ = Playlist(name: name, creator: user, isPublic: isPublic, passcode: passcode)
            save()
        }
    }
    
    func joinPlaylist(playlist: TempPlaylist) {
        let _ = Playlist(name: playlist.name, creator: playlist.creator, isPublic: playlist.isPublic, passcode: playlist.passcode, dateCreated: playlist.dateCreated, context: moc)
        //TODO: Join followers, save to cloud
        save()
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
        //if playlist.creator == UserController.getUserID() {
            playlist.managedObjectContext?.deleteObject(playlist)
        //} else if let user = UserController.getUser() {
            //TODO: Figure out how to remove user from playlist follower, also remove playlist from user following
            //let index = playlist.followers?.indexOfObject(user)
            //playlist.followers.
        //}
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
}




