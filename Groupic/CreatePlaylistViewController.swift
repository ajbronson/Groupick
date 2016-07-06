//
//  CreatePlaylistViewController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/17/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import UIKit

class CreatePlaylistViewController: UIViewController {

    @IBOutlet weak var groupNameTextField: UITextField!
    @IBOutlet weak var passcodeTextField: UITextField!
    @IBOutlet weak var autoButton: UIButton!
    @IBOutlet weak var passcodeLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbarHidden = true
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        if sender.selectedSegmentIndex == 0 {
            passcodeLabel.hidden = false
            passcodeTextField.hidden = false
            autoButton.hidden = false
        } else {
            passcodeLabel.hidden = true
            passcodeTextField.hidden = true
            autoButton.hidden = true
        }
    }
    
    @IBAction func autoButtonTapped(sender: UIButton) {
        passcodeTextField.text = randomString()
    }

    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        
        guard let name = groupNameTextField.text where name.characters.count > 0 else { showAlert("Please Enter A Group Name!"); return }
        
        if segmentedControl.selectedSegmentIndex == 0 {
            guard let passcode = passcodeTextField.text where passcode.characters.count > 0 && passcode.characters.count <= 50 else { showAlert("You have selected a private playlist. \nPlease enter a passcode between 1 and 50 characters."); return }
            PlaylistController.sharedController.createPlaylist(name, isPublic: false, passcode: passcode)
        } else {
            PlaylistController.sharedController.createPlaylist(name, isPublic: true, passcode: nil)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
        alert.addAction(dismissAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func randomString () -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: 4)
        
        for _ in 0 ..< 4 {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString as String
    }
    
}
