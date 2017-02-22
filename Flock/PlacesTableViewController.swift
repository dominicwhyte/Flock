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
import SCLAlertView



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
    
    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            DispatchQueue.main.async {
                if (success) {
                    Utilities.printDebugMessage("Successfully reloaded data and tableview")
                    self.venues = Array(appDelegate.venues.values)
                    //self.venues = self.filterVenuePlannedAttendees(venues: Array(appDelegate.venues.values))

                    self.filteredVenues = []
                    if self.searchController.isActive && self.searchController.searchBar.text != "" {
                        //reloads the table
                        self.filterContentForSearchText(self.searchController.searchBar.text!)
                    }
                    else {
                        
                        self.tableView.reloadData()
                    }
                    
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                completion(success)
            }
        }
    }
    
    func filterVenuePlannedAttendees(venues: [Venue]) -> [Venue] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let users = appDelegate.users
        var venuesToReturn = [Venue]()
        for venue in venues {
            let plannedAttendees = venue.PlannedAttendees
            for (_,attendee) in plannedAttendees {
                let user = users[attendee]
                let plans = user?.Plans
                for (_, plan) in plans! {
                    if(!DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        venue.PlannedAttendees[attendee] = nil
                    }
                }
            }
            venuesToReturn.append(venue)
        }
        return venuesToReturn
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (currentTab == items[0]) {
            tableView.separatorStyle = .none
            tableView.backgroundView?.isHidden = false
            // #warning Incomplete implementation, return the number of items
            if searchController.isActive && searchController.searchBar.text != "" {
                return self.filteredVenues.count
            }
            return self.venues.count
        }
        else {
            tableView.separatorStyle = .none
            Utilities.printDebugMessage("No venues yet for this location.")
            tableView.backgroundView?.isHidden = false
            setupEmptyBackgroundView()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! PlacesTableViewCell
        cell.selectionStyle = .none
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stats = appDelegate.venueStatistics!
        
        //Setup Cell
        if (currentTab == items[0]) {
            var venue : Venue
            
            if searchController.isActive && searchController.searchBar.text != "" {
                venue = filteredVenues[indexPath.row]
            }
            else {
                venue = self.venues[indexPath.row]
            }
            if let lifetime = stats.lifetimeLive[venue.VenueID] {
                cell.rightStatLabel.text = "\(String(lifetime))"
                
            }
            else {
                cell.rightStatLabel.text = "0\nLifetime"
            }
            if let biggestNight = stats.maxPlansInOneNight[venue.VenueID] {
                cell.leftStatLabel.text = "\(String(biggestNight))"
            }
            else {
                cell.leftStatLabel.text = "0\nBiggest Night"
            }
            cell.placesNameLabel.text = venue.VenueName
            self.retrieveImage(imageURL: venue.ImageURL, imageView: cell.backgroundImage)
            //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
            //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
            
            cell.subtitleLabel.text = "Illustrious af"
            
        }
        return cell
        
    }
    
    let inverseGoldenRatio : CGFloat = 0.621
    let l : CGFloat = 12
    let r : CGFloat = 12
    let t : CGFloat = 12
    let b : CGFloat  = 70
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = inverseGoldenRatio * (CGFloat(self.view.frame.width) - l - r) + b + t
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
        
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(PeopleTableViewController.refresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.venues = Array(appDelegate.venues.values)
        //self.venues = filterVenuePlannedAttendees(venues: Array(appDelegate.venues.values))
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Do any additional setup after loading the view.
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = FlockColors.FLOCK_BLUE
        self.navigationController?.navigationBar.isTranslucent = true
        
        //self.view.backgroundColor = FlockColors.FLOCK_GRAY
        self.view.backgroundColor = UIColor.clear
        //empty background view
        setupEmptyBackgroundView()
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        self.updateDataAndTableView { (success) in
            if (!success) {
                Utilities.printDebugMessage("Error reloading table data")
            }
            self.refreshControl?.endRefreshing()
        }
    }
    
    fileprivate let image = UIImage(named: "cat.png")!.withRenderingMode(.alwaysTemplate)
    fileprivate let topMessage = "Favorites"
    fileprivate let bottomMessage = "You don't have any favorites yet. All your favorites will show up here."
    
    func setupEmptyBackgroundView() {
//        let emptyBackgroundView = EmptyBackgroundView(image: image, top: topMessage, bottom: bottomMessage)
//        emptyBackgroundView.backgroundColor = UIColor.purple
        let emptyBackgroundView = UIView(frame: self.view.frame)
        emptyBackgroundView.backgroundColor = UIColor.lightGray//FlockColors.FLOCK_GRAY
        
        // Add image
        let width = CGFloat(100)
        let height = CGFloat(100)
        let xOffset = CGFloat(width/2)
        let yOffset = CGFloat(height/2)
        let imageView = UIImageView(frame: CGRect(x: emptyBackgroundView.center.x - xOffset, y: emptyBackgroundView.center.y - yOffset, width: width, height: height))

        switch self.currentTab {
        case items[1]:
            imageView.image = #imageLiteral(resourceName: "Harvard")
        case items[2]:
            imageView.image = #imageLiteral(resourceName: "Dartmouth")
        case items[3]:
            imageView.image = #imageLiteral(resourceName: "Stanford")
        default:
            break
        }
        
        
         imageView.contentMode = UIViewContentMode.scaleAspectFit
//        let horizConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: emptyBackgroundView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
//        let vertConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: emptyBackgroundView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
//        
//        let widthConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100)
//        let heightConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 100)
//        
//        
//        
//        emptyBackgroundView.addConstraints([vertConstraint, horizConstraint, widthConstraint, heightConstraint])
        
        // Add label(s)
        let label = UILabel(frame: CGRect(x: emptyBackgroundView.center.x - CGFloat(65),y: emptyBackgroundView.center.y - height,width: 130,height: 50))
        //label.center = CGPointMake(160, 284)
        label.textAlignment = NSTextAlignment.center
        label.text = "Coming Soon!"
        label.textColor = UIColor.white
        emptyBackgroundView.addSubview(label)
        
        
        emptyBackgroundView.addSubview(imageView)
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
    
    func changeButtonTitle(title: String, shouldDisable: Bool) {
        latestAttendButton?.isEnabled = !shouldDisable
        latestAttendButton?.setTitle(title, for: .normal)
        if let latestAttendButton = latestAttendButton {
            if(shouldDisable) {
                self.disableButton(button: latestAttendButton)
            } else {
                latestAttendButton.backgroundColor = FlockColors.FLOCK_BLUE
            }
        }
    }
    
    func disableButton(button : UIButton) {
        button.backgroundColor = FlockColors.FLOCK_GRAY
        //button.alpha = 0.7
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
        let todaysDate = DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: "MMMM d")
        let attendButton = DefaultButton(title: "GO TO \(venue.VenueNickName.uppercased()) ON \(todaysDate.uppercased())", dismissOnTap: true) {
            Utilities.printDebugMessage("Attending \(venue.VenueNickName.uppercased())")
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let date = popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]
            
            
            //Add Venue and present popup
            FirebaseClient.addUserToVenuePlansForDate(date: date, venueID: self.venueToPass!.VenueID, userID: appDelegate.user!.FBID, add: true, completion: { (success) in
                if (success) {
                    appDelegate.profileNeedsToUpdate = true
                    Utilities.printDebugMessage("Successfully added plan to attend venue")
                    self.updateDataAndTableView({ (success) in
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                        if (success) {
                            DispatchQueue.main.async {
                                self.displayAttendedPopup(venueName: self.venueToPass!.VenueNickName, attendFullDate: date)
                            }
                        }
                        else {
                            Utilities.printDebugMessage("Error reloading tableview in venues")
                        }
                    })
                }
                else {
                    Utilities.printDebugMessage("Error adding user to venue plans for date")
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                }
            })
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        attendButton.isEnabled = self.shouldAttendButtonBeEnabledUponInitialPopup(appDelegate: appDelegate)
        attendButton.backgroundColor = FlockColors.FLOCK_BLUE
        attendButton.setTitleColor(.white, for: .normal)
        if(!attendButton.isEnabled) {
            self.disableButton(button: attendButton)
        }
        latestAttendButton = attendButton
        // Add buttons to dialog
        popup.addButtons([attendButton])
        
        // Present dialog
        present(popup, animated: true, completion: nil)
    }
    
    func shouldAttendButtonBeEnabledUponInitialPopup(appDelegate : AppDelegate) -> Bool {
        let user = appDelegate.user!
        let today = DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: DateUtilities.Constants.fullDateFormat)
        for (_, plan) in user.Plans {
            let planDate = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.fullDateFormat)
            if(planDate == today && plan.venueID == self.venueToPass!.VenueID) {
                return false
            }
        }
        return true
        
    }
    
    func displayAttendedPopup(venueName : String, attendFullDate : String) {
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess(Utilities.generateRandomCongratulatoryPhrase(), subTitle: "You're going to \(venueName) on \(displayDate)")
    }
    
    func shareWithFlock() {
        print("First button tapped")
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
    func changeButtonTitle(title: String, shouldDisable: Bool)
    
}

