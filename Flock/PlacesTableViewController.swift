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
import SAConfettiView
import CoreLocation



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
    
    @IBOutlet weak var goLiveButton: UIBarButtonItem!
    
    @IBAction func goLiveButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.goLiveButtonPressed = true
        if (!Utilities.isInternetAvailable()) {
            let alert = SCLAlertView()
            _ = alert.showInfo("Oops!", subTitle: "Looks like you don't have internet! Connect to internet so you can go live on Flock")
        }
        else if(CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            appDelegate.locationManager.requestLocation()
            appDelegate.presentNavBarActivityIndicator(navItem: self.navigationItem)
            
        } else {
            let alert = SCLAlertView()
            _ = alert.showInfo("Oops!", subTitle: "Looks like you haven't setup your location services permissions. Hit the settings button in your profile to enable this for a better Flock experience!")
        }
        
    }
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
                    self.getVenuesAndSort()
                    
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
    
    @IBAction func plannedShouldPopUp(_ sender: Any) {
        let alert = SCLAlertView()
        var indexPath: IndexPath?
        var countText: String?
        if let button = sender as? UIButton {
            if let superview = button.superview {
                if let cell = superview.superview as? PlacesTableViewCell {
                    if (self.tableView.indexPath(for: cell) != nil) {
                        indexPath = self.tableView.indexPath(for: cell)
                        countText = cell.leftStatLabel.text
                        Utilities.printDebugMessage("In the index path \(indexPath!.row)")
                    }
                }
            }
        }
        if let indexPath = indexPath, let countText = countText {
            var venue : Venue
            if searchController.isActive && searchController.searchBar.text != "" {
                venue = self.filteredVenues[indexPath.row]
            } else {
                venue = self.venues[indexPath.row]
            }
            var peopleText = "people are"
            if Int(countText) == 1 {
                peopleText = "person is"
            }
            _ = alert.showInfo("Planned", subTitle: "\(countText) \(peopleText) planning to go to \(venue.VenueNickName)")
        }
    }
    
    @IBAction func liveShouldPopUp(_ sender: Any) {
        let alert = SCLAlertView()
        var indexPath: IndexPath?
        var countText: String?
        if let button = sender as? UIButton {
            if let superview = button.superview {
                if let cell = superview.superview as? PlacesTableViewCell {
                    if (self.tableView.indexPath(for: cell) != nil) {
                        indexPath = self.tableView.indexPath(for: cell)
                        countText = cell.rightStatLabel.text
                        Utilities.printDebugMessage("In the index path \(indexPath!.row)")
                    }
                }
            }
        }
        if let indexPath = indexPath, let countText = countText {
            var venue : Venue
            if searchController.isActive && searchController.searchBar.text != "" {
                venue = self.filteredVenues[indexPath.row]
            } else {
                venue = self.venues[indexPath.row]
            }
            var peopleText = "people are"
            if Int(countText) == 1 {
                peopleText = "person is"
            }
            _ = alert.showInfo("Live", subTitle: "\(countText) \(peopleText) live at \(venue.VenueNickName)")
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
            //for showing total lifetimevisits
            //            if let lifetime = stats.lifetimeLive[venue.VenueID] {
            //                cell.rightStatLabel.text = "\(String(lifetime))"
            //
            //            }
            let currentLive = venue.CurrentAttendees.count
            cell.rightStatLabel.text = "\(String(currentLive))"
            var totalPlanned = 0
            if let venueDates = stats.venuePlanCountsForDatesForVenues[venue.VenueID] {
                for (date, count) in venueDates {
                    let daysUntil = DateUtilities.daysUntilPlan(planDate: date)
                    if(DateUtilities.isValidTimeFrame(dayDiff: daysUntil)){
                        totalPlanned += count
                    }
                }
            }
            
            cell.leftStatLabel.text = "\(String(totalPlanned))"
            
            
            //            //TEMP
            //            let A: UInt32 = 0 // UInt32 = 32-bit positive integers (unsigned)
            //            let B: UInt32 = 100
            //            var number = Int(arc4random_uniform(B - A + 1) + A)
            //
            //            let randomLeft = 100 + number
            //            number = Int(arc4random_uniform(B - A + 1) + A)
            //            let randomRight = number + 1000
            //            cell.rightStatLabel.text = "\(randomRight)\nLifetime"
            //            cell.leftStatLabel.text = "\(randomLeft)\nBiggest Night"
            //
            //
            //
            
            
            
            cell.placesNameLabel.text = venue.VenueNickName
            self.retrieveImage(imageURL: venue.ImageURL, venueID: venue.VenueID, imageView: cell.backgroundImage)
            //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
            //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
            
            if let plannedFriends = appDelegate.friendCountPlanningToAttendVenueThisWeek[venue.VenueID] {
                cell.subtitleLabel.text = "\(plannedFriends) planned \(Utilities.setPlurality(string: "friend", count: plannedFriends))"
            }
            else {
                cell.subtitleLabel.text = "Be first to plan!"
            }
            
        }
        
        //        let modelName = UIDevice.current.modelName
        //        if (Utilities.Constants.SMALL_IPHONES.contains(modelName)) {
        //            cell.subtitleLabel.font = UIFont(name: cell.subtitleLabel.font.fontName, size: 12)
        //            cell.leftStatLabel.font = UIFont(name: cell.subtitleLabel.font.fontName, size: 32)
        //            Utilities.printDebugMessage("OLD FONE YO")
        //        }
        
        return cell
        
    }
    
    let inverseGoldenRatio : CGFloat = 0.621
    let l : CGFloat = 12
    let r : CGFloat = 12
    let t : CGFloat = 12
    let b : CGFloat  = 60
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = inverseGoldenRatio * (CGFloat(self.view.frame.width) - l - r) + b + t
        return cellHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var venue : Venue
        if searchController.isActive && searchController.searchBar.text != "" {
            venue = filteredVenues[indexPath.row]
        }
        else {
            venue = self.venues[indexPath.row]
        }
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
    
    func getVenuesAndSort() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.venues = Array(appDelegate.venues.values)
        if let stats = appDelegate.venueStatistics {
            let lifetimelive = stats.lifetimeLive
            self.venues = self.venues.sorted { (venue1, venue2) -> Bool in
                var venue1Live = 0
                var venue2Live = 0
                if (lifetimelive[venue1.VenueID] != nil) {
                    venue1Live = lifetimelive[venue1.VenueID]!
                }
                if (lifetimelive[venue2.VenueID] != nil) {
                    venue2Live = lifetimelive[venue2.VenueID]!
                }
                return venue1Live > venue2Live
            }
        }
        else {
            Utilities.printDebugMessage("No stats")
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
            self?.setupEmptyBackgroundView()
            self?.tableView?.reloadData()
        }
        
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(PeopleTableViewController.refresh(refreshControl:)), for: UIControlEvents.valueChanged)
        self.goLiveButton.setTitleTextAttributes([
            NSFontAttributeName: UIFont(name: "OpenSans-Light", size: 17.0)!,
            NSForegroundColorAttributeName: UIColor.white],
                                                 for: UIControlState.normal)
        super.viewDidLoad()
        
        getVenuesAndSort()
        
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
        case items[0]:
            imageView.image = UIImage()
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
        let label = UILabel(frame: CGRect(x: emptyBackgroundView.center.x - CGFloat(150),y: emptyBackgroundView.center.y - height,width: 300,height: 50))
        //label.center = CGPointMake(160, 284)
        label.textAlignment = NSTextAlignment.center
        label.text = "Coming Soon!"
        label.font = UIFont(name: "OpenSans-Semibold", size: 25)
        if (self.currentTab == items[0]) {
            label.text = ""
        }
        label.textColor = UIColor.white
        emptyBackgroundView.addSubview(label)
        
        
        emptyBackgroundView.addSubview(imageView)
        tableView?.backgroundView = emptyBackgroundView
        
    }
    
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, venueID: String?, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
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
    
    
    func retrieveImage(imageURL : String, venueID: String?, completion: @escaping (_ image: UIImage) -> ()) {
        if let image = imageCache[imageURL] {
            completion(image)
        }
        else {
            FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
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
            FirebaseClient.addUserToVenuePlansForDate(date: date, venueID: self.venueToPass!.VenueID, userID: appDelegate.user!.FBID, add: true, specialEventID: nil, completion: { (success) in
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
        
        //Hacky solution, don't show this on ipads
        if (popupSubView.view.frame.height > self.view.frame.height) {
            Utilities.printDebugMessage("Height error")
        }
        else {
            present(popup, animated: true, completion: nil)
        }
        // Present dialog
        
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
        alert.addButton("Invite Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                self.selectFlockersToInvite(userName: user.Name, venueName : venueName, displayDate : displayDate)
            }
        })
        alert.addButton("Share with Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                Utilities.sendPushNotificationToEntireFlock(title: "\(user.Name) is planning to go to \(venueName) on \(displayDate)!")
                //let newAlert = SCLAlertView()
                //_ = alert.showSuccess("Shared", subTitle: "Your friends have been notified!")
            }
        })
        _ = alert.showSuccess(Utilities.generateRandomCongratulatoryPhrase(), subTitle: "You're going to \(venueName) on \(displayDate)")
        
        //        let confettiView = SAConfettiView(frame: self.view.bounds)
        //        self.view.addSubview(confettiView)
        //        confettiView.startConfetti()
    }
    
    func selectFlockersToInvite(userName : String, venueName : String, displayDate : String) {
        print("First button tapped")
        performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userName, venueName, displayDate))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let peopleSelectorTableViewController = navController.topViewController as? PeopleSelectorTableViewController {
                if let (userName, venueName, displayDate) = sender as? (String, String, String) {
                    peopleSelectorTableViewController.userName = userName
                    peopleSelectorTableViewController.venueName = venueName
                    peopleSelectorTableViewController.displayDate = displayDate
                }
            }
        }
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
    func retrieveImage(imageURL : String, venueID: String?, completion: @escaping (_ image: UIImage) -> ())
    func changeButtonTitle(title: String, shouldDisable: Bool)
    
}

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}
