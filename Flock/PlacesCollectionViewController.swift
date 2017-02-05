//
//  PlacesCollectionViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import PopupDialog

private let reuseIdentifier = "Cell"

class PlacesCollectionViewController: UICollectionViewController {

    var venues : [Venue]?
    var imageCache = [String : UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.venues = Array(appDelegate.venues.values)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.venues!.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PLACE", for: indexPath) as! PlacesCollectionViewCell
        //Setup Cell
        let venue = self.venues![indexPath.row]
        cell.placesNameLabel.text = venue.VenueName
        Utilities.printDebugMessage(venue.VenueName)
        self.retrieveImage(imageURL: venue.ImageURL, imageView: cell.backgroundImage)
        self.retrieveImage(imageURL: venue.LogoURL, imageView: cell.placesLogoImage)
        cell.liveLabel.text = "\(venue.CurrentAttendees.count)"
        cell.plannedLabel.text = "\(venue.PlannedAttendees.count)"
        
        
    
        // Configure the cell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let venue = self.venues![indexPath.row]
        showCustomDialog(venue: venue)
    }
    
    func retrieveImage(imageURL : String, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL) { (image) in
                DispatchQueue.main.async {
                    self.imageCache[imageURL] = image
                    imageView.image = image
                }
            }
        }
        
    }
    
    func showCustomDialog(venue : Venue) {
        
        // Create a custom view controller
        let ratingVC = UIViewController()
        
        // Create the dialog
        let popup = PopupDialog(viewController: ratingVC, buttonAlignment: .horizontal, transitionStyle: .bounceDown, gestureDismissal: true)
        
        // Create first button
        let buttonOne = CancelButton(title: "CANCEL", dismissOnTap: true) {
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "RATE \(venue.VenueName)", dismissOnTap: true) {
            
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        present(popup, animated: true, completion: nil)
    }

}
