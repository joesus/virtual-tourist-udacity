//
//  Pin.swift
//  Virtual Tourist
//
//  Created by A658308 on 10/13/15.
//  Copyright © 2015 Joe Susnick Co. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    // TODO - remember to add photos :)
    //    @NSManaged var photoAlbum: [Photo]?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: NSNumber, longitude: NSNumber, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
    }
}