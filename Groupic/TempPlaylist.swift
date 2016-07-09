//
//  TempPlaylist.swift
//  Groupic
//
//  Created by AJ Bronson on 7/2/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class TempPlaylist {
    
    let name: String
    let isPublic: Bool
    let passcode: String?
    let id: String
    let dateCreated: NSDate
    let changeToken: String?
    let nowPlaying: String?
    var creatorRecord: CKRecordID
    var creator: User?
    var ckRecord: CKRecord
    //songs relationship
    //followers user relationship
    
    
    init?(record: CKRecord) {
        guard let dateCreated = record[kDateCreated] as? NSDate,
            let name = record[kName] as? String,
            let creatorReference = record[kCreator] as? CKReference,
            let isPublic = record[kIsPublic] as? Bool else { return nil }
        self.dateCreated = dateCreated
        self.name = name
        self.id = record.recordID.recordName
        self.changeToken = record.recordChangeTag
        if let nowPlaying = record[kNowPlaying] as? String {
            self.nowPlaying = nowPlaying
        } else {
            self.nowPlaying = nil
        }
        if let passcode = record[kPasscode] as? String {
            self.passcode = passcode
        } else {
            self.passcode = nil
        }
        
        self.isPublic = isPublic
        self.creatorRecord = creatorReference.recordID
        self.ckRecord = record
    }
    
    var cloudKitRecordID: CKRecordID {
        return CKRecordID(recordName: id)
    }
    
}




