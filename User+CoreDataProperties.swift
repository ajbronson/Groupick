//
//  User+CoreDataProperties.swift
//  Groupic
//
//  Created by AJ Bronson on 7/8/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {
    
    @NSManaged var id: String
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var email: String?
    @NSManaged var changeToken: String?
    @NSManaged var created: NSOrderedSet?
    @NSManaged var following: NSOrderedSet?
    @NSManaged var votes: NSOrderedSet?
    @NSManaged var addedSongs: NSSet?
    @NSManaged var cloudKitRecordName: String?

}
