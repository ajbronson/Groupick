//
//  SongTableViewCell.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    
    @IBOutlet weak var songImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var totalVotesLabel: UILabel!
    @IBOutlet weak var upVoteButton: UIButton!
    @IBOutlet weak var downVoteButton: UIButton!
    
    var song: Song?
    var delegate: songVoteProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateWithNoButtons(song: Song) {
        self.song = song
        titleLabel.text = song.title
        artistLabel.text = song.artist
        if let imageData = song.image {
            songImage.image = UIImage(data: imageData)
        }
        totalVotesLabel.text = ""
        upVoteButton.hidden = true
        downVoteButton.hidden = true
    }
    
    func updateWith(song: Song) {
        upVoteButton.hidden = false
        downVoteButton.hidden = false
        self.song = song
        titleLabel.text = song.title
        artistLabel.text = song.artist
        if let imageData = song.image {
            songImage.image = UIImage(data: imageData)
        }
        totalVotesLabel.text = "\(returnAllVotes())"
        
        
        if let voteArray = song.votes?.array as? [Vote] {
            var found = false
            var voteUp = false
            for vote in voteArray {
                if vote.creator.id == UserController.getUserID() {
                    found = true
                    if let voteDirection = vote.vote {
                        if Int(voteDirection) == 1 {
                            voteUp = true
                        }
                    }
                }
            }
            if found {
                if voteUp {
                    downVoteButton.setImage(UIImage(named: "thumbs-down"), forState: .Normal)
                    upVoteButton.setImage(UIImage(named: "filledThumbUp"), forState: .Normal)
                } else {
                    downVoteButton.setImage(UIImage(named: "filledThumbDown"), forState: .Normal)
                    upVoteButton.setImage(UIImage(named: "thumbs-up"), forState: .Normal)
                }
            } else {
                downVoteButton.setImage(UIImage(named: "thumbs-down"), forState: .Normal)
                upVoteButton.setImage(UIImage(named: "thumbs-up"), forState: .Normal)
            }
        }

    }

    @IBAction func voteUpButtonTapped(sender: UIButton) {
        createVote(1)
    }
    
    @IBAction func voteDownButtonTapped(sender: UIButton) {
        createVote(-1)
    }
    
    func createVote(int: Int) {
        if let song = song {
            if let songVotes = song.votes?.array as? [Vote] {
                var found = false
                var index = 0
                for i in 0..<songVotes.count {
                    if songVotes[i].creator.id == UserController.getUserID() {
                        found = true
                        index = i
                        break
                    }
                }
                
                if found {
                    if let vote = song.votes?[index] as? Vote, voteInt = vote.vote {
                        if Int(voteInt) != int {
                            SongController.sharedController.addVoteToSong(song, voteDirection: int, playlist: song.playlist.id)
                        }
                        SongController.sharedController.deleteVote(vote)
                        delegate?.reloadCellVotes(self, song: song, numberOfVotes: returnAllVotes())
                    }
                } else {
                    SongController.sharedController.addVoteToSong(song, voteDirection: int, playlist: song.playlist.id)
                    delegate?.reloadCellVotes(self, song: song, numberOfVotes: returnAllVotes())
                }
            } 
        }
    }
    
    func returnAllVotes() -> Int {
        
        if let song = song, voteArray = song.votes?.array as? [Vote] {
            let totalVotesArray = voteArray.flatMap({$0.vote})
            var intArray = [Int]()
            for number in totalVotesArray {
                intArray.append(Int(number))
            }
            let totalVotes = intArray.reduce(0, combine: +)
            return totalVotes
        } else {
            return 0
        }
    }
}

protocol songVoteProtocol {
    func reloadCellVotes(sender: SongTableViewCell, song: Song, numberOfVotes: Int)
}

