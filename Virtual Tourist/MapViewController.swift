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
    
    @IBOutlet weak var mapView: MKMapView!
    var pins: [Pin]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pins = fetchAllPins()
        addPins()
        setInitialLocation()
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            return [Pin]()
        }
    }
    
    func addPins() {
        // create pins
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
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        let latitude = Float(pin.coordinate.latitude)
        let longitude = Float(pin.coordinate.longitude)
        Pin(latitude: latitude, longitude: longitude, context: self.sharedContext)
        saveContext()
        self.mapView.addAnnotation(pin)
    }
}
