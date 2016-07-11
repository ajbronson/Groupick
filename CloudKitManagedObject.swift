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
    
    var id: String { get set }
    var recordType: String { get }
    var cloudKitRecord: CKRecord? { get }
    var changeToken: String? { get set }
    
}


extension CloudKitManagedObject {
    
    func update(record: CKRecord) {
        guard let changeTag = record.recordChangeTag else { return }
        self.changeToken = String(NSKeyedArchiver.archivedDataWithRootObject(changeTag))
        PlaylistController.sharedController.save()
    }
    
    var cloudKitRecordID: CKRecordID {
        return CKRecordID(recordName: id)
    }
}
