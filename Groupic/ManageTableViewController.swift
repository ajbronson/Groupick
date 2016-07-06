//
//  ManageTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/30/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class ManageTableViewController: UITableViewController {
    
    var playlist: Playlist?

    override func viewDidLoad() {
        super.viewDidLoad()
        users += ["Amanda Carlson", "Mike Love", "Nic Laughter", "Alan Barth", "Andrew Carlson"]
        if let playlist = playlist  {
            if playlist.isPublic.boolValue {
                self.navigationController?.toolbarHidden = true
            }
        }
    }
    
    var users: [String] = []

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath)
        cell.textLabel?.text = users[indexPath.row]

        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if playlist?.isPublic.boolValue == false {
                showAlert()
            }
            users.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
 
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Followers"
    }
    
    @IBAction func changePasscodeButtonTapped(sender: UIBarButtonItem) {
        changePasscode()
    }

    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Warning", message: "This user knows your passcode. Would you like to change your passcode for all future users?", preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { (_) in
            self.changePasscode()
        }
        alert.addAction(dismissAction)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func changePasscode() {
        let alert = UIAlertController(title: "Change Passcode", message: nil, preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (text) in
            text.placeholder = "New Passcode"
            text.addTarget(self, action: #selector(ManageTableViewController.textChanged(_:)), forControlEvents: .EditingChanged)
        }
        let dismissAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "Change", style: .Default) { (_) in
            if let textField = alert.textFields?[0] {
                guard let playlist = self.playlist, text =  textField.text where text.characters.count > 0  else { return }
                PlaylistController.sharedController.changePasscode(playlist, newCode: text)
            }
        }
        alert.addAction(dismissAction)
        alert.addAction(okAction)
        alert.actions[1].enabled = false
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func textChanged(sender:AnyObject) {
        let tf = sender as! UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as! UIAlertController
        (alert.actions[1] as UIAlertAction).enabled = (tf.text != "")
    }
}
