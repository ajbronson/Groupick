//
//  PlaylistTableViewCell.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!
    @IBOutlet weak var kingImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateWith(playlist: Playlist) {
        playlistNameLabel.text = playlist.name
        if let songs = playlist.songs?.array as? [Song] where songs.count > 0,
            let imageData = songs[0].image {
            playlistImage.image = UIImage(data: imageData)
        } else {
           playlistImage.image = UIImage(named: "iTunes")
        }
        if playlist.creator.id == UserController.getUserID() {
            var creatorText = "Created by you."
            if let passcode = playlist.passcode {
                creatorText += " Passcode: \(passcode)"
            } else {
                creatorText += " Public, no passcode."
            }
            creatorLabel.text = creatorText
        } else if let first = playlist.creator.firstName,
            let last = playlist.creator.lastName {
            creatorLabel.text = "By \(first) \(last.substringToIndex(last.startIndex.advancedBy(1)))."
        }
        
        if playlist.creator.id == UserController.getUserID() {
            kingImage.image = UIImage(named: "king")
        }
    }

}
