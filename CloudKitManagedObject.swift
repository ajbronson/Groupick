//
//  CloudKitManagedObject.swift
//  Timeline
//
//  Created by AJ Bronson on 6/2/16.
//  Copyright © 2016 Nicholas Laughter. All rights reserved.
//

import Foundation
import CloudKit

@objc protocol CloudKitManagedObject {
    
    var id: String? { get set }
    var recordType: String { get }
    var cloudKitRecord: CKRecord? { get }
    var changeToken: String? { get set }
    
}


extension CloudKitManagedObject {
    
    func update(record: CKRecord) {
        guard let changeTag = record.recordChangeTag else { return }
        self.changeToken = String(NSKeyedArchiver.archivedDataWithRootObject(changeTag))
        PlaylistController.sharedController.save() //TODO: Thinka bout where best to put this..
    }
    
//    var cloudKitRecordID: CKRecordID? {
//        guard let recordIDData = recordIDData else { return nil }
//        return NSKeyedUnarchiver.unarchiveObjectWithData(recordIDData) as? CKRecordID
//    }
//    
//    var cloudKitReference: CKReference? {
//        guard let recordID = self.cloudKitRecordID else { return nil }
//        return CKReference(recordID: recordID, action: .None)
//    }
}
