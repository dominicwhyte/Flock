//
//  MapViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 7/25/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, GMSMapViewDelegate, UIGestureRecognizerDelegate {

    var mapView: GMSMapView!
    var circle: GMSCircle!
    var region : Region?
    var zoomLevel : ZoomLevel = ZoomLevel.max
    
    //For zoom
    var tap : UITapGestureRecognizer!
    
    //QuadTree
    var tree : GQTPointQuadTree!
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the region (hardcoded for now, will come from firebase in future)
        let northEast = CLLocationCoordinate2D(latitude: 40.355148, longitude: -74.648086)
        let southWest = CLLocationCoordinate2D(latitude: 40.337476, longitude: -74.663644)

        let bounds = Bounds(northEast: northEast, southWest: southWest)
        self.region = Region(bounds: bounds, name: "Princeton")
        
        //Create Quadtree
        let qbounds = GQTBounds(minX: southWest.longitude, minY: southWest.latitude, maxX: northEast.longitude, maxY: northEast.latitude)
        tree = GQTPointQuadTree(bounds: qbounds)
        
        //Disable rotation and zoom
        self.mapView.settings.rotateGestures = false
        self.mapView.settings.zoomGestures = false
        
        createSampleEvents()
        
        
        
        // DOUBLE TAP
        tap = UITapGestureRecognizer(target: self, action: #selector(changeZoom))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        mapView.isUserInteractionEnabled = true
        self.mapView.addGestureRecognizer(tap)
        
        self.navigationItem.title = "None"
    }
    var isZoomed = false
    
    
    func changeZoom() {
        Utilities.printDebugMessage("detected")
        switch zoomLevel {
        case .max:
            zoomLevel = ZoomLevel.min
        case .min:
            zoomLevel = ZoomLevel.max
        }
        mapView.animate(toZoom: zoomLevel.rawValue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //tempDisplayLabel.alpha = 0
    }
    
    //Needed since google maps overrides gesture recognizers
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
    override func loadView() {
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.camera(withLatitude: 40.344551, longitude: -74.654682, zoom: zoomLevel.rawValue)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        self.view = mapView
        self.mapView = mapView
        mapView.delegate = self
        // Creates a marker in the center of the map.

        
      
        
        //let circle = GMSCircle(position: camera.target, radius: 30)
        //circle.fillColor = UIColor.red.withAlphaComponent(1.0)
        //circle.strokeColor = UIColor.red.withAlphaComponent(0.5)
        //circle.map = mapView
        
        
    }
    
    func createSampleEvents() {
        var position = CLLocationCoordinate2D(latitude: 40.347195, longitude: -74.653935)
        MapUtilities.createMarker(markerType: MarkerType.party, position: position, title: "Terrace Rager", mapView: mapView, tree: tree)
        
        position = CLLocationCoordinate2D(latitude: 40.344551, longitude: -74.654682)
        MapUtilities.createMarker(markerType: MarkerType.show, position: position, title: "BodyHype Show", mapView: mapView, tree: tree)
        
        position = CLLocationCoordinate2D(latitude: 40.348616, longitude: -74.650538)
        MapUtilities.createMarker(markerType: MarkerType.party, position: position, title: "Cloister Rager", mapView: mapView, tree: tree)
    }
    


    
    //Bound the viewing area
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        //print("\(position.target.latitude) \(position.target.longitude)")
        //circle.position = position.target
        
        
        if let visiblePin = MapUtilities.getNearbyPin(tree: tree, mapView: mapView) {
            self.navigationItem.title = visiblePin.title
        }
    else {
           self.navigationItem.title = ""
        }

        

        var latitude  = position.target.latitude;
        var longitude = position.target.longitude;
        if let region = region {
            if (position.target.latitude > region.bounds.northEast.latitude) {
                latitude = region.bounds.northEast.latitude;
            }
            
            if (position.target.latitude < region.bounds.southWest.latitude) {
                latitude = region.bounds.southWest.latitude;
            }
            
            if (position.target.longitude > region.bounds.northEast.longitude) {
                longitude = region.bounds.northEast.longitude;
            }
            
            if (position.target.longitude < region.bounds.southWest.longitude) {
                longitude = region.bounds.southWest.longitude;
            }
            
            if (latitude != position.target.latitude || longitude != position.target.longitude) {
                
                var l = CLLocationCoordinate2D();
                l.latitude  = latitude;
                l.longitude = longitude;
                Utilities.printDebugMessage("You've left the bounding region")
                mapView.animate(toLocation: l);
            }
        }

    }
    
    

}


enum ZoomLevel : Float {
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
