//
//  SearchSongResultsTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class SearchSongResultsTableViewController: UITableViewController, addSongProtocol {

    var playlist: Playlist?
    
    var resultsArray: [TempSong] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbarHidden = true
    }


    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArray.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("addSongCell", forIndexPath: indexPath) as? AddSongTableViewCell
        cell?.updateWithSong(resultsArray[indexPath.row], playlist: playlist)
        cell?.delegate = self
        cell?.selectionStyle = .None
        return cell ?? UITableViewCell()
    }
    
    func cellAddButtonTapped(song: TempSong, image: UIImage?) {
        if let image = image, playlist = playlist {
            let imageData = UIImagePNGRepresentation(image)
            SongController.sharedController.addSongToPlaylist(playlist, title: song.title, artist: song.artist, trackID: song.trackID, image: imageData)
        }
    }

}
