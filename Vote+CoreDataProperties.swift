//
//  Vote+CoreDataProperties.swift
//  Groupic
//
//  Created by AJ Bronson on 6/20/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Vote {

    @NSManaged var dateCreated: NSDate?
    @NSManaged var id: String
    @NSManaged var vote: NSNumber?
    @NSManaged var changeToken: String?
    @NSManaged var song: Song
    @NSManaged var creator: User

}
