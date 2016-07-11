//
//  SongController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CoreData

class SongController {
    
    enum searchType: String {
        case artist = "artistTerm"
        case song = "songTerm"
    }
    
    static let sharedController = SongController()
    
    func addSongToPlaylist(playlist: Playlist, title: String, artist: String, trackID: String, image: NSData?) {
        let song = Song(playlist: playlist, title: title, artist: artist, trackID: trackID, image: image)
        PlaylistController.sharedController.save()
        if let songRecord = song.cloudKitRecord {
            CloudKitManager.sharedManager.saveRecord(songRecord, completion: { (record, error) in
                if let record = record {
                    song.update(record)
                }
            })
        }
        addSubscriptionToSongVotes(song, completion: { (success, error) in
            if let error = error {
                print("error subscribing to vote - \(error.localizedDescription)")
            }
        })
    }
    
    func deleteSong(song: Song) {
        song.managedObjectContext?.deleteObject(song)
        if let songRecord = song.cloudKitRecord {
            CloudKitManager.sharedManager.deleteRecordWithID(songRecord.recordID, completion: { (recordID, error) in
                if let error = error {
                    print("Error deleting Song - \(error.localizedDescription)")
                }
            })
        }
        PlaylistController.sharedController.save()
        
    }
    
    
    func togglePlayed(song: Song) {
        if let played = song.previouslyPlayed?.boolValue {
            song.previouslyPlayed = !played.boolValue
        } else {
            song.previouslyPlayed = true
        }
        PlaylistController.sharedController.save()
    }
    
    func songWithID(id: String) -> Song? {
        let predicate = NSPredicate(format: "id == %@", argumentArray: [id])
        let request = NSFetchRequest(entityName: "Song")
        request.predicate = predicate
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(request) as? [Song]) ?? nil
        return result?.first
    }
    
    func addVoteToSong(song: Song, vote: Int) {
        if let user = UserController.getUser() {
            let vote = Vote(song: song, creator: user, vote: vote)
            PlaylistController.sharedController.save()
            if let vote = vote, voteRecord = vote.cloudKitRecord {
                CloudKitManager.sharedManager.saveRecord(voteRecord, completion: { (record, error) in
                    if let record = record {
                        vote.update(record)
                    } else if let error = error {
                        print("error saving vote - \(error.localizedDescription)")
                    }
               })
            }
        }
    }
    
    func deleteVote(vote: Vote) {
        vote.managedObjectContext?.deleteObject(vote)
        deleteCloudKitVote(vote)
        PlaylistController.sharedController.save()
    }
    
    func deleteAllVotes(songs: [Song]) {
        for song in songs {
            if let votes = song.votes?.array as? [Vote] {
                for vote in votes {
                    deleteCloudKitVote(vote)
                    vote.managedObjectContext?.deleteObject(vote)
                }
            }
        }

        PlaylistController.sharedController.save()
    }
    
    func deleteCloudKitVote(vote: Vote) {
        if let voteRecord = vote.cloudKitRecord {
            CloudKitManager.sharedManager.deleteRecordWithID(voteRecord.recordID, completion: { (recordID, error) in
                if let error = error {
                    print("error deleting vote - \(error.localizedDescription)")
                }
            })
        }
    }
    
    func addSubscriptionToSongVotes(song: Song, completion: ((success: Bool, error: NSError?) -> Void)?) {
        let predicate = NSPredicate(format: "song == %@", argumentArray: [song.cloudKitRecordID])
        
        CloudKitManager.sharedManager.subscribe(CloudKitManager.RecordTypes.vote.rawValue, predicate: predicate, identifier: song.cloudKitRecordID.recordName, alertBody: "Song Received A New Vote! 😎", contentAvailable: true, desiredKeys: nil, options: .FiresOnRecordCreation) { (subscription, error) in
            if let completion = completion {
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func fetchSongsWithTerm(term:String, type: searchType, completion:(songs: [TempSong]) -> Void) {
        
        var parameters: [String: String] {
            return [
                "media": "music",
                "entity" : "musicTrack",
                "attribute" : type.rawValue,
                "term" : term
            ]
        }
        
        let url = NSURL(string: "https://itunes.apple.com/search?")
        
        NetworkController.performURLRequest(url!, method: .Get, urlParams: parameters, body: nil) { (data, error) in

            guard let data = data,
                let rawJSON = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments),
                let json = rawJSON as? [String: AnyObject],
                let resultDict = json["results"] as? [[String: AnyObject]] else { completion(songs: []); return }
            let songs = resultDict.flatMap({TempSong(dictionary: $0)})
            completion(songs: songs)

        }
    }
}


