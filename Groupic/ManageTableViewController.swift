//
//  ManageTableViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/30/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class ManageTableViewController: UITableViewController {
    
    var playlist: Playlist?
    var users = [TempUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let playlist = playlist  {
            if playlist.isPublic.boolValue {
                self.navigationController?.toolbarHidden = true
            }
        }
        
        setUsers()
    }
    
    func setUsers() {
        guard let playlist = playlist else { return }
        let predicate = NSPredicate(format: "playlist == %@ && user != %@", argumentArray: [playlist.cloudKitRecordID, CKRecordID(recordName: UserController.getUserID())])
        CloudKitManager.sharedManager.fetchRecordsWithType(CloudKitManager.RecordTypes.userPlaylist.rawValue, predicate: predicate, recordFetchedBlock: nil) { (records, error) in
            if let records = records {
                for userPlaylistRecord in records {
                    if let userid = userPlaylistRecord["user"] as? CKReference {
                        CloudKitManager.sharedManager.fetchRecordWithID(userid.recordID, completion: { (record, error) in
                            if let record = record {
                                let user = TempUser(record: record, userPlaylistRecordID: userPlaylistRecord.recordID)
                                if let user = user {
                                    self.users.append(user)
                                    let index = NSIndexPath(forRow: self.users.count - 1, inSection: 0)
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.tableView.insertRowsAtIndexPaths([index], withRowAnimation: .Left)
                                    })
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath)
        cell.textLabel?.text = "\(users[indexPath.row].firstName) \(users[indexPath.row].lastName)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if playlist?.isPublic.boolValue == false {
                showAlert()
            }
            CloudKitManager.sharedManager.deleteRecordWithID(users[indexPath.row].recordID, completion: { (recordID, error) in
                if let error = error {
                    print("error deleting userPlaylist from manager - \(error.localizedDescription)")
                }
            })
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
        let dismissAction = UIAlertAction(title: "No", style: .Default, handler: nil)
        let okAction = UIAlertAction(title: "Yes", style: .Cancel) { (_) in
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

struct TempUser {
    
    let firstName: String
    let lastName: String
    let recordID: CKRecordID
    
    init?(record: CKRecord, userPlaylistRecordID: CKRecordID) {
        guard let first = record[kFirst] as? String,
            let last = record[kLast] as? String else { return nil }
        self.firstName = first
        self.lastName = last
        self.recordID = userPlaylistRecordID
    }
    
}
