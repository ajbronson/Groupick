//
//  TempSong.swift
//  Groupic
//
//  Created by AJ Bronson on 6/28/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation

class TempSong {
    
    let artist: String
    let title: String
    let trackID: String
    let imageURL: String
    
    init?(dictionary: [String: AnyObject]) {
        guard let title = dictionary["trackName"] as? String,
            let artist = dictionary["artistName"] as? String,
            let trackID = dictionary["trackId"] as? Int,
            let imageString = dictionary["artworkUrl100"] as? String else { return nil }
        if dictionary["isStreamable"] as? Bool == true {
            self.artist = artist
            self.title = title
            self.trackID = String(trackID)
            self.imageURL = imageString
        } else {
            return nil
        }

    }
}


