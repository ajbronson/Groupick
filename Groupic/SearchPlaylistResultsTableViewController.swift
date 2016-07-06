//
//  SearchPlaylistResultsTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class SearchPlaylistResultsTableViewController: UITableViewController, joinProtocol {

    
    var resultPlaylists = [TempPlaylist]()
    var delegate: dismissProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbarHidden = true
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultPlaylists.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchPlaylistCell", forIndexPath: indexPath) as? JoinPlaylistTableViewCell
        cell?.updateWith(resultPlaylists[indexPath.row])
        cell?.delegate = self
        return cell ?? UITableViewCell()
    }
    
    func buttonTapped(playlist: TempPlaylist) {
        if playlist.isPublic {
            PlaylistController.sharedController.joinPlaylist(playlist)
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.dismiss()
        } else {
            showAlert(playlist)
        }

    }
    
    func showAlert(playlist: TempPlaylist) {
        let alert = UIAlertController(title: "Enter Passcode", message: "This playlist is private.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (text) in
            text.placeholder = "Passcode"
        }
        let dissmissAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (_) in
            if let textField = alert.textFields?[0],
                let passcode = playlist.passcode {
                if textField.text == passcode {
                    PlaylistController.sharedController.joinPlaylist(playlist)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.delegate?.dismiss()
                } else {
                    self.showAlert(playlist)
                }
            }
        }
        alert.addAction(dissmissAction)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }

}

protocol dismissProtocol {
    func dismiss()
}
