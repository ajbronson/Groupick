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
        if let first = playlist.creator.firstName,
            let last = playlist.creator.lastName {
            creatorLabel.text = "By \(first) \(last.substringToIndex(last.startIndex.advancedBy(1)))."
        } else {
            creatorLabel.text = ""
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
