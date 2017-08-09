//
//  MapViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 7/25/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import GoogleMaps
import Mapbox

class MapViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate /*,MGLMapViewDelegate, UIGestureRecognizerDelegate*/ {
    
    //For zoom
    var zoomLevel : ZoomLevel = ZoomLevel.max
    var tap : UITapGestureRecognizer!
    
    var mapView : MGLMapView?
    
    // Detail Window
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstSubtitleLabel: UILabel!
    
    @IBOutlet weak var secondSubtitleLabel: UILabel!
    
    @IBOutlet weak var interestedButton: UIButton!
    @IBOutlet weak var thereButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView = setupMap()
        
        view.addSubview(mapView!)
        
        // Set the map view‘s delegate property.
        mapView!.delegate = self
        
        populateMap(mapView: mapView!)
        
        // Single Tap Recognition
        tap = UITapGestureRecognizer(target: self, action: #selector(changeZoom))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        
        self.mapView!.addGestureRecognizer(tap)
        
        self.navigationItem.title = "None"
        
        // Stack views appropriately
        
        self.view.bringSubview(toFront: detailView)
        self.view.bringSubview(toFront: titleLabel)
        self.view.bringSubview(toFront: firstSubtitleLabel)
        self.view.bringSubview(toFront: secondSubtitleLabel)
        self.view.bringSubview(toFront: interestedButton)
        self.view.bringSubview(toFront: thereButton)
        
        self.detailView.layer.cornerRadius = 20
    }
    
    func setupMap() -> MGLMapView {
        let mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .darkGray
        
        // Set the map's bounds to Pisa, Italy.
        /*
         let bounds = MGLCoordinateBounds(
         sw: CLLocationCoordinate2D(latitude: 43.7115, longitude: 10.3725),
         ne: CLLocationCoordinate2D(latitude: 43.7318, longitude: 10.4222))
         mapView.setVisibleCoordinateBounds(bounds, animated: false)
         
         */

        mapView.setCenter(MapUtilities.Constants.PRINCETON_LOCATION, animated: false)
        mapView.setZoomLevel(ZoomLevel.max.rawValue, animated: true)
        mapView.isZoomEnabled = false
        mapView.isUserInteractionEnabled = true
        
        return mapView
    }
    
    func populateMap(mapView : MGLMapView) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let activeEventsDict = appDelegate.activeEvents
        for (_,event) in activeEventsDict {
            Utilities.printDebugMessage("Test" + String(event.Pin.coordinate.latitude))
            mapView.addAnnotation(event.Pin)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //mapView!.setZoomLevel(ZoomLevel.max.rawValue, animated: true)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "pisa")
        
        if annotationImage == nil {
            // Leaning Tower of Pisa by Stefan Spieler from the Noun Project.
            var image = UIImage(named: "blue-college-15")!
            
            // The anchor point of an annotation is currently always the center. To
            // shift the anchor point to the bottom of the annotation, the image
            // asset includes transparent bottom padding equal to the original image
            // height.
            //
            // To make this padding non-interactive, we create another image object
            // with a custom alignment rect that excludes the padding.
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
            
            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "pisa")
        }
        
        return annotationImage
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        
        // See if there are any pins in the frame
        if let pins = self.mapView!.visibleAnnotations(in: self.mapView!.frame) {
            // Go through pins to find closest
            
            var title : String?
            var minDistance = Double.infinity
            
            let mapCenter = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            for pin in pins {
                let pinLocation = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
                let pinDistance = pinLocation.distance(from: mapCenter)
                if(pinDistance < minDistance) {
                    minDistance = pinDistance
                    title = pin.title!
                }
            }
            self.titleLabel.text = title
        }
        
        
        
    }
    
    func changeZoom() {
        
        switch zoomLevel {
        case .max:
            zoomLevel = ZoomLevel.min
        case .min:
            zoomLevel = ZoomLevel.max
        }
        self.mapView?.setZoomLevel(zoomLevel.rawValue, animated: true)
    }
    
    
    @IBAction func interestedButtonPressed(_ sender: Any) {
        mapView!.setCenter(MapUtilities.Constants.PRINCETON_LOCATION, animated: false)
    }
    
    
    
    @IBAction func thereButtonPressed(_ sender: Any) {
    }
    
    
    
}


enum ZoomLevel : Double {
    case min = 18.0
    case max = 15.0
}

class Region: NSObject
{
    var bounds : Bounds
    var name : String
    
    init(bounds : Bounds, name : String)
    {
        self.bounds = bounds
        self.name = name
    }
}

class Bounds: NSObject
{
    var northEast : CLLocationCoordinate2D
    var southWest : CLLocationCoordinate2D
    
    init(northEast : CLLocationCoordinate2D, southWest : CLLocationCoordinate2D)
    {
        self.northEast = northEast
        self.southWest = southWest
    }
}
