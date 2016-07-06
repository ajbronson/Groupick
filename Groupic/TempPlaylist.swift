//
//  TempPlaylist.swift
//  Groupic
//
//  Created by AJ Bronson on 7/2/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CloudKit

class TempPlaylist {
    
    let name: String
    let isPublic: Bool
    let passcode: String?
    let id: String
    let dateCreated: NSDate
    let changeToken: String?
    let nowPlaying: String?
    let creator: User
    //songs relationship
    //followers user relationship
    
    
    init?(record: CKRecord) {
        guard let dateCreated = record[kDateCreated] as? NSDate,
            let name = record[kName] as? String,
            let isPublic = record[kIsPublic] as? Bool,
            let passcode = record[kPasscode] as? String,
            let nowPlaying = record[kNowPlaying] as? String else { return nil }
        self.dateCreated = dateCreated
        self.name = name
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        self.nowPlaying = nowPlaying
        self.passcode = passcode
        self.isPublic = isPublic
        self.creator = User(firstName: "Brandi", lastName: "Bronson", id: NSUUID().UUIDString)!
    }
    
    init(name: String, passcode: String? = "1234", id: String = NSUUID().UUIDString, dateCreated: NSDate = NSDate()) {
        self.name = name
        self.passcode = passcode
        self.id = id
        self.dateCreated = dateCreated
        if passcode == nil {
            self.isPublic = true
        } else {
            self.isPublic = false
        }
        self.creator = User(firstName: "Brandi", lastName: "Bronson", id: NSUUID().UUIDString)!
        self.changeToken = nil
        self.nowPlaying = nil
    }
}

