//
//  Photo.swift
//  Virtual Tourist
//
//  Created by A658308 on 10/14/15.
//  Copyright © 2015 Joe Susnick Co. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    @NSManaged var photoData: NSData?
    @NSManaged var location: Pin?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(image: UIImage, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.photoData = UIImagePNGRepresentation(image)
    }

//    init(image: UIImage) {
//        self.image = image
//    }
}