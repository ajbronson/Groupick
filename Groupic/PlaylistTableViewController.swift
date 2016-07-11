//
//  PlaylistTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit
import CoreData

class PlaylistTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserController.getUser() == nil {
            checkIfUserExists()
        }

        PlaylistController.sharedController.fetchedResultsController.delegate = self
        self.navigationController?.toolbarHidden = true
        
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = PlaylistController.sharedController.fetchedResultsController.sections else { return 0 }
        return sections[section].numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell", forIndexPath: indexPath) as? PlaylistTableViewCell,
            playlist = PlaylistController.sharedController.fetchedResultsController.objectAtIndexPath(indexPath) as? Playlist else { return UITableViewCell() }
        cell.updateWith(playlist)
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let playlist = PlaylistController.sharedController.fetchedResultsController.objectAtIndexPath(indexPath) as? Playlist else { return }
            PlaylistController.sharedController.deletePlaylist(playlist)
        }
    }
 
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toPlaylistDetail" {
            guard let songVC = segue.destinationViewController as? SongsTableViewController,
                let index = tableView.indexPathForSelectedRow,
                let playlist = PlaylistController.sharedController.fetchedResultsController.objectAtIndexPath(index) as? Playlist else { return }
            songVC.playlist = playlist
        }
    }
 

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Left)
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Right)
        default:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
        case .Insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Right)
        case .Move:
            guard let indexPath = indexPath,
                newIndexPath = newIndexPath else { return }
            tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        case .Update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    
    func checkIfUserExists() {
        CloudKitManager.sharedManager.fetchLoggedInUserRecord { (record, error) in
            if let userRecord = record {
                let predicate = NSPredicate(format: "cloudKitRecordName = %@", argumentArray: [userRecord.recordID.recordName])
                CloudKitManager.sharedManager.fetchRecordsWithType("User", predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
                    if let records = records where records.count > 0 {
                        let user = User(record: records[0])
                        if let user = user {
                            UserController.saveUser(user)
                        } else {
                            self.createUserAlertController(userRecord.recordID.recordName)
                        }
                    } else {
                        self.createUserAlertController(userRecord.recordID.recordName)
                    }
                })
            } else {
                self.createUserAlertController(NSUUID().UUIDString)
            }
        }
    }
    
    
    var firstNameTextField: UITextField?
    var lastNameTextField: UITextField?
    
    func createUserAlertController(identifier: String) {
        let alert = UIAlertController(title: "Welcome!", message: "Please Enter Your First and Last Name.\n\n This is for your friends to identify you with playlists that you create, and playlists that you join.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (text) in
            text.placeholder = "First Name"
            self.firstNameTextField = text
            text.addTarget(self, action: #selector(PlaylistTableViewController.textChanged(_:)), forControlEvents: .EditingChanged)
        }
        alert.addTextFieldWithConfigurationHandler { (text) in
            text.placeholder = "Last Name"
            self.lastNameTextField = text
            text.addTarget(self, action: #selector(PlaylistTableViewController.textChanged(_:)), forControlEvents: .EditingChanged)
        }
        let okAction = UIAlertAction(title: "Done", style: .Default) { (_) in
            guard let first = self.firstNameTextField?.text, last = self.lastNameTextField?.text where first.characters.count > 0 && last.characters.count > 0  else { return }
            let user = User(firstName: first, lastName: last, cloudKitRecordName: identifier)
            if let user = user {
                UserController.saveUser(user)
            } else {
                self.createUserAlertController(identifier)
            }
        }
        alert.addAction(okAction)
        alert.actions[0].enabled = false
        dispatch_async(dispatch_get_main_queue()) { 
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func textChanged(sender:AnyObject) {
        guard let firstNameTextField = firstNameTextField, lastNameTextField = lastNameTextField else { return }
        let tf = sender as! UITextField
        var resp : UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as! UIAlertController
        (alert.actions[0] as UIAlertAction).enabled = (firstNameTextField.text != "" && lastNameTextField.text != "")
    }

}
