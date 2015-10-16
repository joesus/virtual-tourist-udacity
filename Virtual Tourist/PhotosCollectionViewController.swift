//
//  PhotosCollectionViewController.swift
//  Virtual Tourist
//
//  Created by A658308 on 10/14/15.
//  Copyright © 2015 Joe Susnick Co. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let reuseIdentifier = "Cell"

/* 1 - Define constants */
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "d29c8d1512b10a729d92a22d740edd6c"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"


class PhotosCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var photos: [Photo] = [Photo]()
    var annotationView: MKAnnotationView?
    let sectionInsets = UIEdgeInsets(top: 30.0, left: 30.0, bottom: 30.0, right: 30.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.view.backgroundColor = UIColor.grayColor()
    }
   
    func getImagesFromFlickr(annoation: MKAnnotationView) {
        // reset photos to nothing
        self.photos = [Photo]()

        if let bbox = formatBoundingBox(annoation) {
            /* 2 - API method arguments */
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "bbox": bbox,
                "per_page": "20",
                "nojsoncallback": NO_JSON_CALLBACK
            ]
            
            // 3 - Instantiate session and url
            let session = NSURLSession.sharedSession()
            let urlString = BASE_URL + escapedParameters(methodArguments)
            let url = NSURL(string: urlString)
            let request = NSURLRequest(URL: url!)
            
            // 4 - initialize task for getting data
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                if let error = downloadError {
                    print("Could not complete the request \(error)")
                } else {
                    /* 5 - Success! Parse the data */
                    do {
                        let parsedResult: AnyObject! = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                        parsedResult
                        
                        if let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary {
                            if let photoArray = photosDictionary.valueForKey("photo") as? [[String: AnyObject]] {
                                for photo in photoArray {
                                    if let imageUrlString = photo[EXTRAS] as? String {
                                        let imageURL = NSURL(string: imageUrlString)
                                        if let imageData = NSData(contentsOfURL: imageURL!) {
                                            dispatch_async(dispatch_get_main_queue(), {
                                                let image = UIImage(data: imageData)!
                                                // TODO - fetch from coredata
                                                let pic = Photo(image: image)
                                                self.photos.append(pic)
                                                self.collectionView?.reloadData()
                                            })
                                        }
                                    } else {
                                        print("Problem with imageURLString")
                                    }
                                }
                            } else {
                                print("Issue with photo key")
                            }
                        } else {
                            print("Cant find key 'photos' in \(parsedResult)")
                        }
                    } catch {
                        print("caught error")
                    }
                }
                
            }
            
            /* 9 - Resume (execute) the task */
            task.resume()
            self.collectionView?.reloadData()
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    
        cell.backgroundColor = UIColor.grayColor()
        // Configure the cell
        let imageView = UIImageView(frame: CGRectMake(0, 0, 100, 100))
        imageView.image = self.photos[indexPath.row].image!
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100.0, height: 100.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    // MARK: UICollectionViewDelegate
    
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    func formatBoundingBox(annotation: MKAnnotationView) -> String? {
        let latitude = Double((annotation.annotation!.coordinate.latitude))
        let lng = Double((annotation.annotation!.coordinate.longitude))
    
        // 111 kilometers / 1000 = 111 meters.
        // 1 degree of latitude = ~111 kilometers.
        // 1 / 1000 means an offset of coordinate by 111 meters.
        
        let offset = 1.0 / 5.0
        let latMax = latitude + offset
        let latMin = latitude - offset
        
        // With longitude, things are a bit more complex.
        // 1 degree of longitude = 111km only at equator (gradually shrinks to zero at the poles)
        // So need to take into account latitude too, using cos(lat).
        let lngOffset = offset * cos(latitude * M_PI / 180.0)
        let lngMax = lng + lngOffset
        let lngMin = lng - lngOffset
        
        if lngMax > 180.0 || lngMin < -180.0 || latMax > 90.0 || latMin < -90.0 {
            return nil
        } else {
            return "\(lngMin),\(latMin),\(lngMax),\(latMax)"
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

}
