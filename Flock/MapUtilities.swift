//
//  MapUtilities.swift
//  Flock
//
//  Created by Dominic Whyte on 29.07.17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class MapUtilities {
    
    static func createMarker(markerType : MarkerType, position : CLLocationCoordinate2D, title : String, mapView : GMSMapView, tree : GQTPointQuadTree) {
        var markerView : UIImageView
        var color : UIColor
        switch markerType {
        case MarkerType.party:
            markerView = MarkerImageViews.Party
            color = FlockColors.FLOCK_BLUE
        case MarkerType.show:
            markerView = MarkerImageViews.Show
            color = UIColor.brown
        }
        markerView.tintColor = color
        let marker = GMSMarker(position: position)
        marker.title = title
        marker.iconView = markerView
        marker.tracksViewChanges = true
        marker.map = mapView

        //Add marker to quad tree. Assuming Lat = Y Long = X
        let pin = Pin(title: title, marker: marker)
        tree.add(QuadTreeItem(point: GQTPoint(x: position.longitude, y: position.latitude), pin: pin))
    }
    
    
    static func getNearbyPin(tree : GQTPointQuadTree, mapView : GMSMapView) -> Pin? {
        
        let northEast = mapView.projection.coordinate(for: CGPoint(x: mapView.bounds.width, y: 0 ))
        let southWest = mapView.projection.coordinate(for: CGPoint(x: 0, y: mapView.bounds.height))
        
        let searchBounds = GQTBounds(minX: southWest.longitude, minY: southWest.latitude, maxX: northEast.longitude, maxY: northEast.latitude)
        
        let items = tree.search(with: searchBounds) as! [QuadTreeItem]
        if (items.count != 0) {
            return items[0].pin //Can change this as needed to return different pins in the view
        }
        return nil
      
    }
}

class Pin: NSObject
{
    var title : String
    var marker : GMSMarker
    
    init(title : String, marker : GMSMarker)
    {
        self.title = title
        self.marker = marker
    }
}

class QuadTreeItem : NSObject, GQTPointQuadTreeItem {
    let gqtPoint : GQTPoint
    let pin : Pin
    
    init(point : GQTPoint, pin : Pin) {
        self.gqtPoint = point
        self.pin = pin
    }
    
    func point() -> GQTPoint {
        return gqtPoint
    }
}


struct MarkerImageViews {
    static let Party = UIImageView(image: UIImage(named: "Map-Party-Icon")!.withRenderingMode(.alwaysTemplate))
    static let Show = UIImageView(image: UIImage(named: "Map-Show-Icon")!.withRenderingMode(.alwaysTemplate))
}

enum MarkerType {
    case party
    case show
}
