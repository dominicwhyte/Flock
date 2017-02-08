//
//  PlacesCollectionViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import PopupDialog
import BTNavigationDropdownMenu

private let reuseIdentifier = "Cell"

class PlacesCollectionViewController: UICollectionViewController, VenueDelegate {
    
    let items = ["Princeton", "Harvard", "Dartmouth", "Stanford"]
    var currentTab : String = "Princeton" //Which college
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "PLACE"
    fileprivate let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    internal var venueToPass: Venue?
    
    fileprivate let itemsPerRow: CGFloat = 1
    var venues = [Venue]()
    var filteredVenues = [Venue]()
    
    var imageCache = [String : UIImage]()
    let searchController = UISearchController(searchResultsController: nil)
    
    func displayVenuePopupWithVenueIDForDay(venueID : String, date : Date) {
        var selectedVenue : Venue? = nil
        for venue in venues {
            Utilities.printDebugMessage("checking")
            if venue.VenueID == venueID {
                selectedVenue = venue
                break
            }
        }
        if let selectedVenueFound : Venue = selectedVenue {
            self.venueToPass = selectedVenueFound
            showCustomDialog(venue: selectedVenueFound, startDisplayDate: date)
            
        }
        else {
            Utilities.printDebugMessage("Error: cannot find venue with venueID to show")
        }
        
    }
    
    
    override func viewDidLoad() {
        //empty background view
        setupEmptyBackgroundView()
        self.collectionView?.backgroundColor = UIColor.white
        //Search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY
        
        searchController.searchBar.placeholder = "Search                                                                                     "
        
        //nav bar
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: items[0], items: items as [AnyObject])
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = FlockColors.FLOCK_BLUE
        menuView.menuTitleColor = UIColor.white
        menuView.cellTextLabelColor = FlockColors.FLOCK_BLUE
        self.navigationItem.titleView = menuView
        
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            self?.currentTab = self!.items[indexPath]
            self?.collectionView?.reloadData()
        }
        
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.venues = Array(appDelegate.venues.values)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = FlockColors.FLOCK_BLUE
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.view.backgroundColor = FlockColors.FLOCK_GRAY
    }
    
    fileprivate let image = UIImage(named: "cat.png")!.withRenderingMode(.alwaysTemplate)
    fileprivate let topMessage = "Favorites"
    fileprivate let bottomMessage = "You don't have any favorites yet. All your favorites will show up here."
    
    func setupEmptyBackgroundView() {
        let emptyBackgroundView = EmptyBackgroundView(image: image, top: topMessage, bottom: bottomMessage)
        collectionView?.backgroundView = emptyBackgroundView
    }
   
  

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (currentTab == items[0]) {
            collectionView.backgroundView?.isHidden = true
            // #warning Incomplete implementation, return the number of items
            if searchController.isActive && searchController.searchBar.text != "" {
                return self.filteredVenues.count
            }
            return self.venues.count
        }
        else {
            //tableView.separatorStyle = .none
            collectionView.backgroundView?.isHidden = false
            return 0
        }
        
    }
    

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlacesCollectionViewCell
        //Setup Cell
        if (currentTab == items[0]) {
            var venue : Venue
            
            if searchController.isActive && searchController.searchBar.text != "" {
                venue = filteredVenues[indexPath.row]
            }
            else {
                venue = self.venues[indexPath.row]
            }
            
            cell.placesNameLabel.text = venue.VenueName
            self.retrieveImage(imageURL: venue.ImageURL, imageView: cell.backgroundImage)
            //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
            //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
            cell.subtitleLabel.text = "\(venue.CurrentAttendees.count) live   \(venue.PlannedAttendees.count) planned"
        }
        return cell
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let venue = self.venues[indexPath.row]
        self.venueToPass = venue
        showCustomDialog(venue: venue, startDisplayDate: nil)
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
    
    func filterContentForSearchText(_ searchText: String) {
        self.filteredVenues = (venues.filter({( venue : Venue) -> Bool in
            return venue.VenueName.lowercased().contains(searchText.lowercased())
        }))
        collectionView?.reloadData()
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
    
    //Date is optional, this is if you want to start on a certain day of the week
    func showCustomDialog(venue : Venue, startDisplayDate : Date?) {
        
        // Create a custom view controller
        let popupSubView = PopupSubViewController(nibName: "PopupSubViewController", bundle: nil)
        popupSubView.delegate = self
        
        if let date = startDisplayDate {
            popupSubView.setStartDate(date: date)
        }
        
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


extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

extension PlacesCollectionViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension PlacesCollectionViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

protocol VenueDelegate: class {
    var venueToPass : Venue? {get set}
    func retrieveImage(imageURL : String, completion: @escaping (_ image: UIImage) -> ())
    
}
