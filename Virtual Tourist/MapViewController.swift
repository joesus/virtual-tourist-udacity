//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by A658308 on 10/13/15.
//  Copyright © 2015 Joe Susnick Co. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var photosCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    
    var pins: [Pin]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPins()
        setInitialLocation()
        
        // Set initial height of photosCollectionView to 0
        photosCollectionViewHeight.constant = 0.0
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            return [Pin]()
        }
    }
    
    // MARK - CoreData Methods

    lazy var sharedContext: NSManagedObjectContext = {
    return CoreDataStackManager.sharedInstance().managedObjectContext
    }()

    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
}

extension MapViewController {
    func setInitialLocation() {
        // get coordinates and zoom level
        let latitude = NSUserDefaults.standardUserDefaults().doubleForKey("latitude")
        let longitude = NSUserDefaults.standardUserDefaults().doubleForKey("longitude")
        let zoomLevel = NSUserDefaults.standardUserDefaults().integerForKey("zoomLevel")
        if latitude != 0 && longitude != 0 {
            setCenterCoordinate(CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoomLevel: zoomLevel, animated: true)
        }
    }
    
    func getZoomLevel() -> Int {
        return Int(log2(360 * (Double(self.mapView.frame.size.width/256) / self.mapView.region.span.longitudeDelta)) + 1)
    }
    
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        return self.mapView.centerCoordinate
    }
    
    func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool){
        let span = MKCoordinateSpanMake(0, 360 / pow(2, Double(zoomLevel)) * Double(self.mapView.frame.size.width) / 256)
        self.mapView.setRegion(MKCoordinateRegionMake(coordinate, span), animated: animated)
    }
    
    // MARK - MapViewDelegate methods
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        print("finished rendering")
        saveMapPosition()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.accessibilityValue = "pin_for_\(annotation.title)"
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        photosCollectionViewHeight.constant = 500

        let childVC = self.childViewControllers[0] as! PhotosCollectionViewController

        // get the pin associated with the coordinates
        let pin = self.pins?.filter({ $0.longitude == view.annotation?.coordinate.longitude && $0.latitude == view.annotation?.coordinate.latitude }).first
        
        
        childVC.getImagesFromFlickr(pin!)
        
        // focus the map on the pin
        mapView.setCenterCoordinate(view.annotation!.coordinate, animated: true)
    }

    func saveMapPosition() {
        let centerCoordinate = getCenterCoordinate()
        // User NSUserDefaults for initial location later will user core data entities for pins
        NSUserDefaults.standardUserDefaults().setDouble(centerCoordinate.latitude, forKey: "latitude")
        NSUserDefaults.standardUserDefaults().setDouble(centerCoordinate.longitude, forKey: "longitude")
        NSUserDefaults.standardUserDefaults().setInteger(getZoomLevel(), forKey: "zoomLevel")
    }
    
    @IBAction func dropPin(sender: UILongPressGestureRecognizer) {
        // Create pin
        let point = sender.locationInView(self.mapView)
        let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        let latitude = Double(pointAnnotation.coordinate.latitude)
        let longitude = Double(pointAnnotation.coordinate.longitude)
        let pin = Pin(latitude: latitude, longitude: longitude, context: self.sharedContext)
        saveContext()
        self.pins?.append(pin)
        self.mapView.addAnnotation(pointAnnotation)
    }
    
    @IBAction func dismissCollectionView(sender: UITapGestureRecognizer) {
        photosCollectionViewHeight.constant = 0.0
    }
    
    func addPins() {
        // create pins
        self.pins = fetchAllPins()
        if let pins = self.pins {
            for pin in pins {
                let lat = CLLocationDegrees(pin.latitude as Double)
                let long = CLLocationDegrees(pin.longitude)
                
                // The lat and long are used to create a CLLocationCoordinates2D instance.
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                self.mapView.addAnnotation(annotation)
            }
        }
    }
}
