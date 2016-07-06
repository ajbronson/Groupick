//
//  SongsTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class SongsTableViewController: UITableViewController, songVoteProtocol, nextButtonProtocol {
    
    var playlist: Playlist?
    var songs: [Song]?
    var nowPlayingSong: Song?
    var previouslyPlayedSongs = [Song]()
    var songOrder = [(Int, Song)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = playlist?.name
        MusicController.sharedController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        
        songOrder = [(Int, Song)]()
        previouslyPlayedSongs = [Song]()
        if playlist?.creator.id == UserController.getUserID() {
            self.navigationController?.toolbarHidden = false
        }
        if let songs = playlist?.songs?.array as? [Song] {
            
            for song in songs {
                if song.previouslyPlayed?.boolValue == true {
                    previouslyPlayedSongs.append(song)
                } else if song.id == playlist?.nowPlaying {
                    nowPlayingSong = song
                } else {
                    if let votes = song.votes?.array as? [Vote] {
                        let count = votes.flatMap({Int($0.vote!)}).reduce(0, combine: +)
                        var didAdd = false
                        for i in 0..<songOrder.count {
                            let vote = songOrder[i].0
                            if count > vote {
                                songOrder.insert((count, song), atIndex: i)
                                didAdd = true
                                break
                            }
                        }
                        if !didAdd {
                            songOrder.append((count, song))
                        }
                    }
                }
            }
        }
        songs = songOrder.flatMap({$1})
        tableView.reloadData()
    }
    
    
    
    // MARK: - Table view data source
    
    
    func reloadCellVotes(sender: SongTableViewCell, song: Song, numberOfVotes: Int) {
        guard let index = tableView.indexPathForCell(sender) else { return }
        tableView.reloadRowsAtIndexPaths([index], withRowAnimation: .Automatic)
        let tuple  = songOrder[index.row]
        
        if (numberOfVotes > tuple.0 && index.row != 0) || (numberOfVotes < tuple.0 && index.row != songOrder.count - 1) {
            
            if tuple.0 < numberOfVotes {
                
                for i in 1...index.row {
                    let checkTuple = songOrder[index.row - i]
                    
                    if (numberOfVotes <= checkTuple.0 && song.dateCreated.isGreaterThanDate(checkTuple.1.dateCreated)) || i == index.row || numberOfVotes < checkTuple.0 {
                        var newIndex: NSIndexPath
                        if i == index.row && (song.dateCreated.isLessThanDate(checkTuple.1.dateCreated) && numberOfVotes >= checkTuple.0) {
                            newIndex = NSIndexPath(forItem: (index.row - i), inSection: whichSectionForSongs())
                        } else if numberOfVotes > checkTuple.0 {
                            newIndex = NSIndexPath(forItem: (index.row - i), inSection: whichSectionForSongs())
                        } else {
                            newIndex = NSIndexPath(forItem: (index.row - i + 1), inSection: whichSectionForSongs())
                            
                        }
                        songOrder.removeAtIndex(index.row)
                        songOrder.insert((numberOfVotes, song), atIndex: newIndex.row)
                        songs = songOrder.flatMap({$1})
                        tableView.beginUpdates()
                        tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Left)
                        tableView.insertRowsAtIndexPaths([newIndex], withRowAnimation: .Right)
                        tableView.endUpdates()
                        break
                    }
                }
            } else {
                
                for i in index.row + 1..<songOrder.count {
                    let checkTuple = songOrder[i]
                    
                    if (numberOfVotes >= checkTuple.0 && song.dateCreated.isLessThanDate(checkTuple.1.dateCreated)) || i == songOrder.count - 1 || numberOfVotes > checkTuple.0 {
                        var newIndex: NSIndexPath
                        if (i == songOrder.count - 1) && (numberOfVotes <= checkTuple.0 && song.dateCreated.isGreaterThanDate(checkTuple.1.dateCreated)) {
                            
                            newIndex = NSIndexPath(forItem: (i), inSection: whichSectionForSongs())
                        } else if numberOfVotes < checkTuple.0 {
                            newIndex = NSIndexPath(forItem: (i), inSection: whichSectionForSongs())
                        } else {
                            newIndex = NSIndexPath(forItem: (i - 1), inSection: whichSectionForSongs())
                        }
                        songOrder.removeAtIndex(index.row)
                        songOrder.insert((numberOfVotes, song), atIndex: newIndex.row)
                        songs = songOrder.flatMap({$1})
                        tableView.beginUpdates()
                        tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Left)
                        tableView.insertRowsAtIndexPaths([newIndex], withRowAnimation: .Right)
                        tableView.endUpdates()
                        break
                    }
                }
            }
        } else {
            songOrder[index.row].0 = numberOfVotes
        }
        
    }
    
    func whichSectionForSongs() -> Int {
        if nowPlayingSong != nil {
            return 1
        } else {
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if nowPlayingSong != nil {
            if section == 0 {
                return 1
            } else if section == 1 {
                return songs?.count ?? 0
            } else {
                return previouslyPlayedSongs.count
            }
        } else if previouslyPlayedSongs.count > 0 {
            if section == 0 {
                return songs?.count ?? 0
            } else {
                return previouslyPlayedSongs.count
            }
        } else {
            return songs?.count ?? 0
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell", forIndexPath: indexPath) as? SongTableViewCell
        
        if nowPlayingSong != nil {
            if previouslyPlayedSongs.count > 0 {
                if indexPath.section == 0 {
                    if let song = nowPlayingSong {
                        cell?.updateWithNoButtons(song)
                    }
                } else if indexPath.section == 1 {
                    if let songs = songs {
                        cell?.updateWith(songs[indexPath.row])
                    }
                } else {
                    cell?.updateWithNoButtons(previouslyPlayedSongs[indexPath.row])
                }
            } else {
                if indexPath.section == 0 {
                    if let song = nowPlayingSong {
                        cell?.updateWithNoButtons(song)
                    }
                } else if indexPath.section == 1 {
                    if let songs = songs {
                        cell?.updateWith(songs[indexPath.row])
                    }
                }
            }
            
        } else if previouslyPlayedSongs.count > 0 {
            if indexPath.row == 0 {
                if let songs = songs {
                    cell?.updateWith(songs[indexPath.row])
                }
            } else {
                cell?.updateWithNoButtons(previouslyPlayedSongs[indexPath.row])
            }
        } else if let songs = songs {
            cell?.updateWith(songs[indexPath.row])
        }
        
        cell?.delegate = self
        cell?.selectionStyle = .None
        return cell ?? UITableViewCell()
        
    }
    
    func numberOfSections() -> Int {
        if nowPlayingSong != nil {
            return previouslyPlayedSongs.count > 0 ? 3 : 2
        } else if previouslyPlayedSongs.count > 0 && songs?.count > 0 {
            return 2
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if nowPlayingSong != nil {
            if previouslyPlayedSongs.count > 0 {
                if section == 0 {
                    return "Now Playing"
                } else if section == 1 {
                    return "Up Next"
                } else {
                    return "Previously Played"
                }
                
            } else {
                if section == 0 {
                    return "Now Playing"
                } else {
                    return "Up Next"
                }
            }
        } else if previouslyPlayedSongs.count > 0 {
            if section == 0 {
                return "Up Next"
            } else {
                return "Previously Played"
            }
        } else {
            return "Up Next"
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if let songs = songs {
            if nowPlayingSong != nil {
                if indexPath.section == 1 {
                    if songs[indexPath.row].addedBy?.id == UserController.getUserID() || playlist?.creator.id == UserController.getUserID() {
                        return true
                    }
                }
            } else if previouslyPlayedSongs.count > 0 {
                if indexPath.section == 0 {
                    if songs[indexPath.row].addedBy?.id == UserController.getUserID() || playlist?.creator.id == UserController.getUserID() {
                        return true
                    }
                }
                
            } else {
                if songs[indexPath.row].addedBy?.id == UserController.getUserID() || playlist?.creator.id == UserController.getUserID() {
                    return true
                }
            }
        }

        return false
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let song = songOrder[indexPath.row].1
            SongController.sharedController.deleteSong(song)
            songOrder.removeAtIndex(indexPath.row)
            songs?.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toAddCell" {
            if let destinationVC = segue.destinationViewController as? SearchSongTableViewController {
                destinationVC.playlist = playlist
            }
        } else if segue.identifier == "toManage" {
            if let destinationVC = segue.destinationViewController.childViewControllers[0] as? ManageTableViewController {
                destinationVC.playlist = playlist
            }
        }
    }
    
    @IBAction func playButtonTapped(sender: UIBarButtonItem) {
        guard let playlist = playlist else { return }
        if playlist.nowPlaying == nil {
            setNextSongAsNowPlaying(false)
        } else {
            MusicController.sharedController.play()
        }
    }
    
    @IBAction func pauseButtonTapped(sender: UIBarButtonItem) {
        MusicController.sharedController.pause()
    }
    
    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        setNextSongAsNowPlaying(true)
    }
    
    func nextButtonClicked() {
        setNextSongAsNowPlaying(true)
    }
    
    func setNextSongAsNowPlaying(next: Bool) {
        guard let playlist = playlist else { return }
        
        if songOrder.count > 0 {
            if let trackID = songOrder[0].1.trackID {
                let song = songOrder[0].1
                songOrder.removeAtIndex(0)
                songs = songOrder.flatMap({$1})
                //let index = NSIndexPath(forRow: 0, inSection: whichSectionForSongs())
                //tableView.deleteRowsAtIndexPaths([index], withRowAnimation: .Automatic)
                MusicController.sharedController.controller.setQueueWithStoreIDs([trackID])
                //let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                if nowPlayingSong == nil {
                    PlaylistController.sharedController.nowPlaying(playlist, song: song)
                    nowPlayingSong = song
                    tableView.reloadData()
                    //tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                    //tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
                } else if let npSong = nowPlayingSong {
                    addSongToPreviousPlaylist(npSong)
                    PlaylistController.sharedController.nowPlaying(playlist, song: song)
                    nowPlayingSong = song
                    //tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                }
                if next {
                    MusicController.sharedController.nextSong()
                }
                MusicController.sharedController.play()
            }
        } else if previouslyPlayedSongs.count > 0 {
            if let song = nowPlayingSong {
                addSongToPreviousPlaylist(song)
            }
            for song in previouslyPlayedSongs {
                SongController.sharedController.togglePlayed(song)
                songOrder.append((0, song))
            }
            songs = previouslyPlayedSongs
            previouslyPlayedSongs = [Song]()
            nowPlayingSong = nil
            playlist.nowPlaying = nil
            if let songs = playlist.songs?.array as? [Song] {
                SongController.sharedController.deleteAllVotes(songs)
            }
            MusicController.sharedController.stop()
        }
        tableView.reloadData()
    }
    
    func addSongToPreviousPlaylist(song: Song) {
        SongController.sharedController.togglePlayed(song)
        var added = false
        for i in 0..<previouslyPlayedSongs.count {
            if song.dateCreated.isLessThanDate(previouslyPlayedSongs[i].dateCreated) {
                previouslyPlayedSongs.insert(song, atIndex: i)
                added = true
                break
            }
        }
        
        if !added {
            previouslyPlayedSongs.append(song)
        }
    }
}

extension NSDate {
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
}
