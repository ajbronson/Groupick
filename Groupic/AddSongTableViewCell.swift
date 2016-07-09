//
//  AddSongTableViewCell.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class AddSongTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var song: TempSong?
    var delegate: addSongProtocol?

    
    func updateWithSong(song: TempSong, playlist: Playlist?) {
        self.song = song
        titleLabel.text = song.title
        artistLabel.text = song.artist
        addButton.setImage(UIImage(named: "+Button"), forState: .Normal)
        self.songImage.image = nil
        if let url = NSURL(string: song.imageURL) {
            ImageController.fetchImage(url, completion: { (image) in
                dispatch_async(dispatch_get_main_queue(), { 
                    self.songImage.image = image
                })
            })
        }
        
    }
    
    func toggleButton() {
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func addButtonTapped(sender: UIButton) {
        addButton.setImage(UIImage(named: "greenCheck"), forState: .Normal)
        if let song = song {
            delegate?.cellAddButtonTapped(song, image: songImage.image)
        }
    }
    
}

protocol addSongProtocol {
    func cellAddButtonTapped(song: TempSong, image: UIImage?)
}