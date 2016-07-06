//
//  Song+CoreDataProperties.swift
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

extension Song {

    @NSManaged var artist: String?
    @NSManaged var changeToken: String?
    @NSManaged var dateCreated: NSDate
    @NSManaged var id: String?
    @NSManaged var image: NSData?
    @NSManaged var imageURL: String?
    @NSManaged var title: String?
    @NSManaged var trackID: String?
    @NSManaged var previouslyPlayed: NSNumber?
    @NSManaged var playlist: Playlist
    @NSManaged var votes: NSOrderedSet?
    @NSManaged var addedBy: User?

}
