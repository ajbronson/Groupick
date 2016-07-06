//
//  SongController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation

class SongController {
    
    enum searchType: String {
        case artist = "artistTerm"
        case song = "songTerm"
    }
    
    static let sharedController = SongController()
    
    func addSongToPlaylist(playlist: Playlist, title: String, artist: String, trackID: String, image: NSData?) {
        let _ = Song(playlist: playlist, title: title, artist: artist, trackID: trackID, image: image)
        PlaylistController.sharedController.save()
    }
    
    func deleteSong(song: Song) {
        song.managedObjectContext?.deleteObject(song)
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
    
    func addVoteToSong(song: Song, vote: Int) {
        if let user = UserController.getUser() {
            let _ = Vote(song: song, creator: user, vote: vote)
            PlaylistController.sharedController.save()
        }
    }
    
    func deleteVote(vote: Vote) {
        vote.managedObjectContext?.deleteObject(vote)
        PlaylistController.sharedController.save()
    }
    
    func deleteAllVotes(songs: [Song]) {
        for song in songs {
            if let votes = song.votes?.array as? [Vote] {
                for vote in votes {
                    vote.managedObjectContext?.deleteObject(vote)
                }
            }
        }

        PlaylistController.sharedController.save()
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


