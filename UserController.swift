//
//  UserController.swift
//  Groupic
//
//  Created by AJ Bronson on 6/23/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation

class UserController {
    
    static let keyLoggedInUser = "login"
    
    //I'm not setting the user yet
    static func saveUser(user: User) {
        NSUserDefaults.standardUserDefaults().setObject(user.dictionaryCopy, forKey: keyLoggedInUser)
    }
    
    static func getUserID() -> String {
        guard let loggedInUser = NSUserDefaults.standardUserDefaults().objectForKey(keyLoggedInUser) as? [String : AnyObject],
            let id = loggedInUser[kID] as? String else { return "" }
        return id
    }
    
    static func getUser() -> User? {
        guard let loggedInUser = NSUserDefaults.standardUserDefaults().objectForKey(keyLoggedInUser) as? [String : AnyObject],
            let id = loggedInUser[kID] as? String,
            let firstName = loggedInUser[kFirst] as? String,
            let lastName = loggedInUser[kLast] as? String else { return nil }
        return User(firstName: firstName, lastName: lastName, id: id)
    }
    
    static func removeUser() {
        NSUserDefaults.standardUserDefaults().setObject("", forKey: keyLoggedInUser)
    }
}