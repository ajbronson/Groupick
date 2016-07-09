//
//  JoinPlaylistTableViewCell.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class JoinPlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!
    
    var delegate: joinProtocol?
    var playlist: TempPlaylist?
    
    func updateWith(playlist: TempPlaylist) {
        self.playlist = playlist
        playlistLabel.text = playlist.name
        creatorLabel.text = ""
        if let user = UserController.userWithID(playlist.creatorRecord), first = user.firstName, last = user.lastName {
            self.creatorLabel.text = "By \(first) \(last.substringToIndex(last.startIndex.advancedBy(1)))."
            playlist.creator = user
        } else {
            CloudKitManager.sharedManager.fetchRecordWithID(playlist.creatorRecord) { (record, error) in
                if let record = record {
                    let user = User(record: record)
                    if let user = user, first = user.firstName, last = user.lastName {
                        dispatch_async(dispatch_get_main_queue(), { 
                            self.creatorLabel.text = "By \(first) \(last.substringToIndex(last.startIndex.advancedBy(1)))."
                            self.playlist?.creator = user
                        })
                    }
                }
            }
       }
    }
    
    @IBAction func joinButtonTapped(sender: UIButton) {
        if let playlist = playlist {
            delegate?.buttonTapped(playlist)
        }
    }
    
}

protocol joinProtocol {
    func buttonTapped(playlist: TempPlaylist)
}
