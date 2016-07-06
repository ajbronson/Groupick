//
//  Playlist+CoreDataProperties.swift
//  Groupic
//
//  Created by AJ Bronson on 7/2/16.
//  Copyright © 2016 PrecisionCodes. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Playlist {
    
    @NSManaged var name: String
    @NSManaged var id: String?
    @NSManaged var passcode: String?
    @NSManaged var isPublic: NSNumber
    @NSManaged var dateCreated: NSDate
    @NSManaged var changeToken: String?
    @NSManaged var creator: User
    @NSManaged var followers: NSOrderedSet?
    @NSManaged var songs: NSOrderedSet?
    @NSManaged var nowPlaying: String?


}
