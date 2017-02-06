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

class PlacesCollectionViewController: UICollectionViewController, VenueDelegate {
    // MARK: - Properties
    fileprivate let reuseIdentifier = "PLACE"
    //fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let sectionInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    
    internal var venueToPass: Venue?
    
    fileprivate let itemsPerRow: CGFloat = 2
    var venues : [Venue]?
    var imageCache = [String : UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.venues = Array(appDelegate.venues.values)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlacesCollectionViewCell
        //Setup Cell
        let venue = self.venues![indexPath.row]
        cell.placesNameLabel.text = venue.VenueName
        Utilities.printDebugMessage(venue.VenueName)
        
        self.retrieveImage(imageURL: venue.ImageURL, imageView: cell.backgroundImage)
        self.retrieveImage(imageURL: venue.LogoURL, imageView: cell.placesLogoImage)
        cell.liveLabel.text = "\(venue.CurrentAttendees.count)"
        cell.plannedLabel.text = "\(venue.PlannedAttendees.count)"
        cell.placesLogoImage.setRounded()
        
    
        // Configure the cell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let venue = self.venues![indexPath.row]
        self.venueToPass = venue
        showCustomDialog(venue: venue)
    }
    
    //Retrieve image with caching
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
    
    func retrieveImage(imageURL : String, completion: @escaping (_ image: UIImage) -> ()) {
        if let image = imageCache[imageURL] {
            completion(image)
        }
        else {
            FirebaseClient.getImageFromURL(imageURL) { (image) in
                completion(image!)
                self.imageCache[imageURL] = image
            }
        }
    }
    
    func showCustomDialog(venue : Venue) {
        
        // Create a custom view controller
        let popupSubView = PopupSubViewController(nibName: "PopupSubViewController", bundle: nil)
        popupSubView.delegate = self
        // Create the dialog
        let popup = PopupDialog(viewController: popupSubView, buttonAlignment: .horizontal, transitionStyle: .bounceDown, gestureDismissal: true)
        
        
        // Create second button
        let attendButton = DefaultButton(title: "ATTEND \(venue.VenueName) on [insert date]", dismissOnTap: true) {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            FirebaseClient.addUserToVenuePlansForDate(date: popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex], venueID: self.venueToPass!.VenueID, userID: appDelegate.user!.FBID, completion: { (success) in
                if (success) {
                    Utilities.printDebugMessage("Successfully added plan to attend venue")
                }
                else {
                    
                }
            })
        }
        
        // Add buttons to dialog
        popup.addButtons([attendButton])
        
        // Present dialog
        present(popup, animated: true, completion: nil)
    }

}


extension PlacesCollectionViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

protocol VenueDelegate: class {
    var venueToPass : Venue? {get set}
    func retrieveImage(imageURL : String, completion: @escaping (_ image: UIImage) -> ())
    
}
