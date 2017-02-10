//
//  PlacesTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 08/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import PopupDialog
import BTNavigationDropdownMenu



class PlacesTableViewController: UITableViewController, VenueDelegate {
    
    let items = ["Princeton", "Harvard", "Dartmouth", "Stanford"]
    var currentTab : String = "Princeton" //Which college
    
    fileprivate let reuseIdentifier = "PLACE"
    fileprivate let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    internal var venueToPass: Venue?
    
    fileprivate let itemsPerRow: CGFloat = 1
    var venues = [Venue]()
    var filteredVenues = [Venue]()
    
    var imageCache = [String : UIImage]()
    let searchController = UISearchController(searchResultsController: nil)


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (currentTab == items[0]) {
            tableView.backgroundView?.isHidden = true
            // #warning Incomplete implementation, return the number of items
            if searchController.isActive && searchController.searchBar.text != "" {
                return self.filteredVenues.count
            }
            return self.venues.count
        }
        else {
            //tableView.separatorStyle = .none
            tableView.backgroundView?.isHidden = false
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! PlacesTableViewCell
        cell.selectionStyle = .none
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
    
    let inverseGoldenRatio : CGFloat = 0.621
    let l : CGFloat = 25.0
    let r : CGFloat = 25.0
    let t : CGFloat = 25.0
    let b : CGFloat  = 60.5
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = inverseGoldenRatio * (CGFloat(self.view.frame.width) - l - r) + b + t
        Utilities.printDebugMessage("\(self.view.frame.width)    \(cellHeight)")
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let venue = self.venues[indexPath.row]
        self.venueToPass = venue
        showCustomDialog(venue: venue, startDisplayDate: nil)
    }
    
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
        //Search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY
        
        searchController.searchBar.placeholder = "Search                                                                                     "
        tableView.tableHeaderView = searchController.searchBar
        //nav bar
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: items[0], items: items as [AnyObject])
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = FlockColors.FLOCK_BLUE
        menuView.menuTitleColor = UIColor.white
        menuView.cellTextLabelColor = FlockColors.FLOCK_BLUE
        self.navigationItem.titleView = menuView
        
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            self?.currentTab = self!.items[indexPath]
            self?.tableView?.reloadData()
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
        tableView?.backgroundView = emptyBackgroundView
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
        tableView?.reloadData()
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
    
    func changeButtonTitle(title: String) {
        latestAttendButton?.setTitle(title, for: .normal)
    }
    
    var latestAttendButton : DefaultButton?
    
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
        let attendButton = DefaultButton(title: "ATTEND \(venue.VenueName.uppercased())", dismissOnTap: true) {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            FirebaseClient.addUserToVenuePlansForDate(date: popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex], venueID: self.venueToPass!.VenueID, userID: appDelegate.user!.FBID, completion: { (success) in
                if (success) {
                    Utilities.printDebugMessage("Successfully added plan to attend venue")
                }
                else {
                    
                }
            })
        }
        latestAttendButton = attendButton
        // Add buttons to dialog
        popup.addButtons([attendButton])
        
        // Present dialog
        present(popup, animated: true, completion: nil)
    }

}








extension PlacesTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension PlacesTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

protocol VenueDelegate: class {
    var venueToPass : Venue? {get set}
    func retrieveImage(imageURL : String, completion: @escaping (_ image: UIImage) -> ())
    func changeButtonTitle(title: String)
    
}

