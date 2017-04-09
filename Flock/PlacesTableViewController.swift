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
    
    //let items = ["All", "Open Mon", "Open Tues", "Open Wed", "Open Thu", "Open Fri", "Open Sat", "Open Sun" ]
    var items : [String] = []
    var displayItems : [String] = []
    var currentTab : String = "All Clubs" //Which college
    
    struct Constants {
        static let FLOCK_INVITE_REQUEST_CELL_SIZE = 129.0
    }
    
    var flockInviteRequestCollectionView : UICollectionView?
    
    fileprivate let reuseIdentifier = "PLACE"
    fileprivate let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    internal var venueToPass: Venue?
    
    fileprivate let itemsPerRow: CGFloat = 1
    var venues = [Venue]()
    var totalPlansInDateRangeForVenueID = [String:Int]()
    var totalPlansOnDateForVenueID = [String : [String : Int]]()
    var filteredVenues = [Venue]()
    var invitationRequests = [Invitation]()
    
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
            
        }
        else if (CLLocationManager.authorizationStatus() == .notDetermined) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.locationManager.requestWhenInUseAuthorization()
        }
        else {
            let alert = SCLAlertView()
            let _ = alert.addButton("Settings", action: {
                UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
            })
            _ = alert.showInfo("Oops!", subTitle: "Looks like you haven't setup your location services permissions. Hit the settings button in your profile to enable this for a better Flock experience!")
        }
        
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (invitationRequests.count == 0) {
            return 1
        }
        return 2
    }
    
    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            DispatchQueue.main.async {
                if (success) {
                    self.setDataForInvitesRequestsCollectionView()
                    self.flockInviteRequestCollectionView?.reloadData()
                    Utilities.printDebugMessage("Successfully reloaded data and tableview")
                    
                    if(self.currentTab == self.items[0]) {
                        self.getVenuesAndSort()
                    } else {
                        if let itemIndex = self.displayItems.index(of: self.currentTab) {
                            self.filterContentForDayOpen(self.items[itemIndex])
                        }
                    }
                    
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
            _ = alert.showInfo("Planned", subTitle: "\(countText) \(peopleText) planning to go to \(venue.VenueNickName) in the coming days")
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
            _ = alert.showInfo("Live", subTitle: "\(countText) \(peopleText) currently live at \(venue.VenueNickName)")
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
        tableView.separatorStyle = .none
        tableView.backgroundView?.isHidden = false
        
        if (invitationRequests.count != 0) {
            if (section == 0) {
                return 1
            }
        }
        if searchController.isActive && searchController.searchBar.text != "" {
            return self.filteredVenues.count
        }
        return self.venues.count
        
//        if (currentTab == items[0]) {
//            tableView.separatorStyle = .none
//            tableView.backgroundView?.isHidden = true
//            if (invitationRequests.count != 0) {
//                if (section == 0) {
//                    return 1
//                }
//            }
//            if searchController.isActive && searchController.searchBar.text != "" {
//                return self.filteredVenues.count
//            }
//            return self.venues.count
//        }
//        else {
//            tableView.separatorStyle = .none
//            Utilities.printDebugMessage("No venues yet for this location.")
//            tableView.backgroundView?.isHidden = false
//            setupEmptyBackgroundView()
//            self.view.setNeedsLayout()
//            self.view.layoutIfNeeded()
//            return 0
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0 && invitationRequests.count != 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "INVITE_REQUEST_TABLE_VIEW_CELL", for: indexPath) as! InviteRequestTableViewCell
            cell.setCollectionViewDataSourceDelegate(self)
            flockInviteRequestCollectionView = cell.collectionView
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! PlacesTableViewCell
        cell.selectionStyle = .none
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
        //Setup Cell
        
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
        
        var closestEvent : Event?
        for (_,event) in venue.Events {
            if (DateUtilities.dateIsWithinOneCalendarWeek(date: event.EventDate)) {
                if (closestEvent == nil) {
                    closestEvent = event
                }
                else if (DateUtilities.daysUntilPlan(planDate: closestEvent!.EventDate) > DateUtilities.daysUntilPlan(planDate: event.EventDate)) {
                    closestEvent = event
                }
            }
        }
        if let closestEvent = closestEvent {
            if (DateUtilities.dateIsToday(date: closestEvent.EventDate)) {
                cell.nextOpenLabel.text = "Next open tonight"
            }
            else {
                cell.nextOpenLabel.text = "Next open \(DateUtilities.convertDateToStringByFormat(date: closestEvent.EventDate, dateFormat: "E"))"
            }
            
        }
        else {
            cell.nextOpenLabel.text = "Next open TBD"
        }
        
        let currentLive = venue.CurrentAttendees.count
        cell.rightStatLabel.text = "\(String(currentLive))"
        
        
        if(self.currentTab == "All Clubs") {
            if let plannedCount = totalPlansInDateRangeForVenueID[venue.VenueID] {
                cell.leftStatLabel.text = "\(plannedCount)"
            }
            else {
                cell.leftStatLabel.text = "0"
            }
        } else {
            if let stats = appDelegate.venueStatistics {
                if let venueCountsForDates = stats.venuePlanCountsForDatesForVenues[venue.VenueID] {
                
                    if let plannedCount = venueCountsForDates[DateUtilities.getDateFromString(date: self.currentTab)] {
                        cell.leftStatLabel.text = "\(plannedCount)"
                    } else {
                        cell.leftStatLabel.text = "0"
                    }
                } else {
                    cell.leftStatLabel.text = "0"
                }
            }
            else {
                cell.leftStatLabel.text = "0"
            }
        }
        
        cell.placesNameLabel.text = venue.VenueNickName
        self.retrieveImage(imageURL: venue.ImageURL, venueID: venue.VenueID, imageView: cell.backgroundImage)
        //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
        //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
        
        if(self.currentTab != "All Clubs") {
            if let planDictForDates = appDelegate.friendCountPlanningToAttendVenueForDates[venue.VenueID]{
                if let plannedFriends = planDictForDates[self.currentTab] {
                    cell.subtitleLabel.text = "\(plannedFriends) planned \(Utilities.setPlurality(string: "friend", count: plannedFriends))"
                } else {
                    cell.subtitleLabel.text = "Be first to plan!"
                }
            }
        }
        else {
            if let plannedFriends = appDelegate.friendCountPlanningToAttendVenueThisWeek[venue.VenueID] {
                cell.subtitleLabel.text = "\(plannedFriends) planned \(Utilities.setPlurality(string: "friend", count: plannedFriends))"
            }
            else {
                cell.subtitleLabel.text = "Be first to plan!"
            }
        }
//                        //TEMP
//                        let A: UInt32 = 0 // UInt32 = 32-bit positive integers (unsigned)
//                        let B: UInt32 = 100
//                        var number = Int(arc4random_uniform(B - A + 1) + A)
//            
//                        let randomLeft = 20 + number
//                        number = Int(arc4random_uniform(B - A + 1) + A)
//                        let randomRight = 0
//                        cell.rightStatLabel.text = "\(randomRight)"
//                        cell.leftStatLabel.text = "\(randomLeft)"
            
            
            
            
            
        
        
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
        if (indexPath.section == 0 && invitationRequests.count != 0) {
            return CGFloat(Constants.FLOCK_INVITE_REQUEST_CELL_SIZE)
        }
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
        
        //Utilities.printDebugMessage(self.currentTab)
        if(self.currentTab != "All Clubs") {
            let dateString = self.currentTab
            let date = DateUtilities.getDateFromString(date: dateString)
            Utilities.printDebugMessage("I'm being passed a date appropriately")
            showCustomDialog(venue: venue, startDisplayDate: date)
        } else {
            showCustomDialog(venue: venue, startDisplayDate: nil)
        }
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
        
        //compute totalPlansInDateRangeForVenueID
        var totalPlansInDateRangeForVenueID = [String:Int]()
        if let stats = appDelegate.venueStatistics {
            for (_,venue) in appDelegate.venues {
                totalPlansInDateRangeForVenueID[venue.VenueID] = 0
                if let venueDates = stats.venuePlanCountsForDatesForVenues[venue.VenueID] {
                    var venueDict = [String : Int]()
                    for (date, count) in venueDates {
                        let daysUntil = DateUtilities.daysUntilPlan(planDate: date)
                        if(DateUtilities.isValidTimeFrame(dayDiff: daysUntil)){
                            totalPlansInDateRangeForVenueID[venue.VenueID]! = count + totalPlansInDateRangeForVenueID[venue.VenueID]!
                        }
                        // Add to specific date for venue
                        venueDict[DateUtilities.getStringFromDate(date: date)] = count
                    }
                    
                }
            }
        }
        
        self.totalPlansInDateRangeForVenueID = totalPlansInDateRangeForVenueID
        
        
        
        self.venues = Array(appDelegate.venues.values)

            self.venues = self.venues.sorted { (venue1, venue2) -> Bool in
                var venue1Planned = 0
                var venue2Planned = 0
                if (totalPlansInDateRangeForVenueID[venue1.VenueID] != nil) {
                    venue1Planned = totalPlansInDateRangeForVenueID[venue1.VenueID]!
                }
                if (totalPlansInDateRangeForVenueID[venue2.VenueID] != nil) {
                    venue2Planned = totalPlansInDateRangeForVenueID[venue2.VenueID]!
                }
                return venue1Planned > venue2Planned
            }
        
    }
    
    
    override func viewDidLoad() {
        
        //Itms array for filter
        self.setupItemsArray(dayCount: DateUtilities.Constants.NUMBER_OF_DAYS_TO_DISPLAY)
        
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
        
        var displayItems : [String] = []
        for item in items {
            if(item != items[0]) {
                let date = DateUtilities.getDateFromString(date: item)
                let title = "\(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.dropdownDisplayFormat))"
                displayItems.append(title)
            } else {
                displayItems.append("All Clubs")
            }
        }
        self.displayItems = displayItems
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: items[0], items: displayItems as [AnyObject])
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = FlockColors.FLOCK_BLUE
        menuView.menuTitleColor = UIColor.white
        menuView.cellTextLabelColor = FlockColors.FLOCK_BLUE
        self.navigationItem.titleView = menuView
        
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            self?.currentTab = self!.items[indexPath]
            //self?.setupEmptyBackgroundView()
            menuView.menuTitle.text = "poop:"
            self!.filterContentForDayOpen(self!.items[indexPath])
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
        
        //setup collection view for invites
        setDataForInvitesRequestsCollectionView()
    }
    
    func setDataForInvitesRequestsCollectionView() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        invitationRequests = []
        let user = appDelegate.user!
        for (_,invite) in user.Invitations {
            if (DateUtilities.dateIsWithinValidTimeframe(date: invite.date)) {
                if (invite.accepted == nil) {
                    invitationRequests.append(invite)
                }
            }
        }
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
    
    func filterContentForDayOpen(_ filterForDate: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fullVenues = Array(appDelegate.venues.values)
        
        if(filterForDate == items[0]) {
            self.venues = fullVenues.sorted { (venue1, venue2) -> Bool in
                var venue1Planned = 0
                var venue2Planned = 0
                if (self.totalPlansInDateRangeForVenueID[venue1.VenueID] != nil) {
                    venue1Planned = self.totalPlansInDateRangeForVenueID[venue1.VenueID]!
                }
                if (self.totalPlansInDateRangeForVenueID[venue2.VenueID] != nil) {
                    venue2Planned = self.totalPlansInDateRangeForVenueID[venue2.VenueID]!
                }
                return venue1Planned > venue2Planned
            }
        }
        else {
            self.venues = (fullVenues.filter({( venue : Venue) -> Bool in
                for (_,event) in venue.Events {
                    if(DateUtilities.convertDateToStringByFormat(date: event.EventDate, dateFormat: DateUtilities.Constants.fullDateFormat) == filterForDate) {
                        return true
                    }
                }
                return false
            }))
            
            
            
            
            self.venues = self.venues.sorted { (venue1, venue2) -> Bool in
                var venue1Planned = 0
                var venue2Planned = 0
                
                if let stats = appDelegate.venueStatistics {
                    if let venue1CountsForDates : [Date:Int] = stats.venuePlanCountsForDatesForVenues[venue1.VenueID] {
                        if venue1CountsForDates[DateUtilities.getDateFromString(date: self.currentTab)] != nil{
                            venue1Planned = venue1CountsForDates[DateUtilities.getDateFromString(date: self.currentTab)]!
                        }
                    }
                    if let venue2CountsForDates = stats.venuePlanCountsForDatesForVenues[venue2.VenueID] {
                        if venue2CountsForDates[DateUtilities.getDateFromString(date: self.currentTab)] != nil {
                            venue2Planned = venue2CountsForDates[DateUtilities.getDateFromString(date: self.currentTab)]!
                        }
                    }
                    
                    
                }


                return venue1Planned > venue2Planned
            }
        }
    }
    
    
    func setupItemsArray(dayCount : Int) {
        var fullArray : [String] = ["All Clubs"] // Should always be first option in items array
        var dayOfWeekArray : [String] = []
        var date = Date()
        for _ in 0...(dayCount-1) {
            fullArray.append(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.fullDateFormat))
            dayOfWeekArray.append(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.shortDayOfWeekFormat))
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        self.items = fullArray
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
    
    func changeButtonTitle(title: String) {
        latestAttendButton?.backgroundColor = FlockColors.FLOCK_BLUE
        latestAttendButton?.setTitle(title, for: .normal)
    }
    
    
    var latestAttendButton : DefaultButton?
    
    
    func performSegueToSelector(userID : String, venueID : String, fullDate : String, plannedAttendeesForDate : [String: String], specialEventID : String?) {
        self.performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendeesForDate, specialEventID))
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
        let todaysDate = DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: "MMMM d")
        let attendButton = DefaultButton(title: "GO TO \(venue.VenueNickName.uppercased()) ON \(todaysDate.uppercased())", dismissOnTap: true) {

            if (popupSubView.buttonIsInviteButton) {
                Utilities.printDebugMessage("Invite flock!")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let userID = appDelegate.user!.FBID
                
                
                
                let venueID = self.venueToPass!.VenueID
                let fullDate = popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForDate = popupSubView.allFriendsForDate[popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForDate = [String:String]()
                
                for user in plannedFriendUsersForDate {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForDate[user.FBID] = user.FBID
                }
                let specialEventID = popupSubView.specialEventID
                self.performSegueToSelector(userID: userID, venueID: venueID, fullDate: fullDate, plannedAttendeesForDate: plannedAttendeesForDate, specialEventID: specialEventID)
                //popupSubView.performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendeesForDate, specialEventID))
            }
            else {
                Utilities.printDebugMessage("Attending \(venue.VenueNickName.uppercased())")
                let date = popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForDate = popupSubView.allFriendsForDate[popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForDate = [String:String]()
                
                for user in plannedFriendUsersForDate {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForDate[user.FBID] = user.FBID
                }
                
                //Add Venue and present popup
                self.attendVenueWithConfirmation(date: date, venueID: self.venueToPass!.VenueID, add: true, specialEventID: popupSubView.specialEventID, plannedFriendAttendeesForDate: plannedAttendeesForDate)
            }

        }
        
        
        //attendButton.isEnabled = self.shouldAttendButtonBeEnabledUponInitialPopup(appDelegate: appDelegate)
        attendButton.backgroundColor = FlockColors.FLOCK_BLUE

        attendButton.setTitleColor(.white, for: .normal)
//        if(!attendButton.isEnabled) {
//            self.disableButton(button: attendButton)
//        }
        latestAttendButton = attendButton
        // Add buttons to dialog
        popup.addButtons([attendButton])
        
        //Hacky solution, don't show this on ipads
        if (popupSubView.view.frame.height > self.view.frame.height) {
            Utilities.printDebugMessage("Height error")
        }
        else {
            popupSubView.setAttendButtonTitle()
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
    
    func displayAttendedPopup(venueName : String, venueID: String, attendFullDate : String, plannedAttendees: [String:String], specialEventID: String?) {
        let fullDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.fullDateFormat)
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        alert.addButton("Invite Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                self.selectFlockersToInvite(userID: user.FBID, venueID : venueID, fullDate : fullDate, plannedAttendees: plannedAttendees, specialEventID: specialEventID)
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
    
    func selectFlockersToInvite(userID : String, venueID: String, fullDate : String, plannedAttendees: [String:String], specialEventID: String?) {
        print("First button tapped")
        performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendees, specialEventID))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "hasSeenWalkthrough") {
            Utilities.printDebugMessage("Walkthrough has NOT been seen!")
            //Utilities.showWalkthrough(vcDelegate: self, vc: self)
            
            UserDefaults.standard.set(true, forKey: "hasSeenWalkthrough") // Set defaults so no walkthrough next time
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.simpleTBC!.animateToTab(2, completion: { (navCon) in
                if let navCon = navCon as? UINavigationController {
                    let vc = navCon.topViewController as! PeopleTableViewController
                    vc.tableView.setContentOffset(CGPoint.zero, animated: true)
                    
                    
                    
                    
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                    viewController.alpha = 0.5
                    
                    appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
                    
                }
            })
            
            
            userDefaults.set(true, forKey: "hasSeenWalkthrough")
            userDefaults.synchronize()
        } else {
            Utilities.printDebugMessage("Walkthrough has been seen!")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let peopleSelectorTableViewController = navController.topViewController as? PeopleSelectorTableViewController {
                if let (userID, venueID, fullDate, plannedAttendees, specialEventID) = sender as? (String, String, String, [String:String], String?) {
                    peopleSelectorTableViewController.userID = userID
                    peopleSelectorTableViewController.venueID = venueID
                    peopleSelectorTableViewController.fullDate = fullDate
                    peopleSelectorTableViewController.plannedAttendees = plannedAttendees
                    peopleSelectorTableViewController.specialEventID = specialEventID
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
    func changeButtonTitle(title: String)
    
}
/*
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
 
 }*/

extension PlacesTableViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Utilities.printDebugMessage(String(invitationRequests.count))
        return invitationRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FLOCK_INVITE_REQUEST_COLLECTION_VIEW_CELL", for: indexPath) as! InviteRequestCollectionViewCell
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let invitationRequest = invitationRequests[indexPath.row]
        
        cell.imageView.makeViewCircle()
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.clipsToBounds = true
        
        cell.blackBackgroundView.isHidden = true
        
        if let venue = appDelegate.venues[invitationRequest.venueID] {
            if (invitationRequest.specialEventID != nil) {
                if let event = appDelegate.specialEvents[invitationRequest.specialEventID!] {
                    cell.nameLabel.text = "\(event.EventName) Invite"
                }
                else {
                    cell.nameLabel.text = "\(venue.VenueNickName) Invite"
                }
                self.retrieveImage(imageURL: venue.ImageURL, venueID: venue.VenueID, imageView: cell.imageView)
            }
            else {
                cell.nameLabel.text = "\(venue.VenueNickName) Invite"
                self.retrieveImage(imageURL: venue.ImageURL, venueID: venue.VenueID, imageView: cell.imageView)
            }
        }
        else {
            cell.nameLabel.text = "Pending Invite"
        }
        
        
        return cell
    }
    
    func attendVenueWithConfirmation(date : String, venueID : String, add : Bool, specialEventID : String?, plannedFriendAttendeesForDate : [String : String]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //        let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        let (loadingScreen, foundView) = Utilities.presentLoadingScreenAutoGetView()
        FirebaseClient.addUserToVenuePlansForDate(date: date, venueID: venueID, userID: appDelegate.user!.FBID, add: true, specialEventID: specialEventID, completion: { (success) in
            if (success) {
                appDelegate.profileNeedsToUpdate = true
                Utilities.printDebugMessage("Successfully added plan to attend venue")
                self.updateDataAndTableView({ (success) in
                    if (success) {
                        DispatchQueue.main.async {
                            let venue = appDelegate.venues[venueID]!
                            //Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: foundView)
                            self.displayAttendedPopup(venueName: venue.VenueNickName, venueID: venueID, attendFullDate: date, plannedAttendees: plannedFriendAttendeesForDate, specialEventID: specialEventID)
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
    
    
    
    func getPlannedAttendees(venue : Venue, fullDate : String) -> [String:String] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let friends = appDelegate.friends
        var plannedFriendAttendeesForDate = [String:String]()
        let plannedAttendees = venue.PlannedAttendees
        
        for (_, plannedAttendee) in plannedAttendees {
            if let friend = friends[plannedAttendee] {
                for (_,plan) in friend.Plans {
                    if(DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        if(plan.venueID == venue.VenueID) {
                            let fullDatePlan = DateUtilities.getStringFromDate(date: plan.date)
                            if (fullDatePlan == fullDate) {
                                plannedFriendAttendeesForDate[friend.FBID] = friend.FBID
                            }
                        }
                    }
                }
            }
        }

        
        return plannedFriendAttendeesForDate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Collection view at row \(collectionView.tag) selected index path \(indexPath)")
        let invitationRequest = invitationRequests[indexPath.row]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let fromUser = appDelegate.users[invitationRequest.fromUserID], let venue = appDelegate.venues[invitationRequest.venueID] {
            let alert = SCLAlertView()
            let _ = alert.addButton("Accept", action: {
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                var plannedFriendAttendeesForDate = [String:String]()
                if let venue = appDelegate.venues[invitationRequest.venueID] {
                    plannedFriendAttendeesForDate = self.getPlannedAttendees(venue: venue, fullDate: DateUtilities.getStringFromDate(date: invitationRequest.date))
                }
                FirebaseClient.acceptOrRejectInviteRequest(accepted: true, uniqueInvitationID: invitationRequest.inviteID, userID: appDelegate.user!.FBID, completion: { (success) in
                    let venue = appDelegate.venues[invitationRequest.venueID]!
                    Utilities.sendPushNotification(title: "\(appDelegate.user!.Name) accepted your invite to \(venue.VenueNickName) for \(DateUtilities.convertDateToStringByFormat(date: invitationRequest.date, dateFormat: DateUtilities.Constants.uiDisplayFormat))", toUserFBID: invitationRequest.fromUserID)
                    if (!success) {
                        Utilities.printDebugMessage("Failure accepting invite request")
                    }
                    else {
                        Utilities.printDebugMessage("Success accepting invite request")
                    }
                    DispatchQueue.main.async {
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                    }
                    
                    self.attendVenueWithConfirmation(date: DateUtilities.getStringFromDate(date: invitationRequest.date), venueID: invitationRequest.venueID, add: true, specialEventID: invitationRequest.specialEventID, plannedFriendAttendeesForDate: plannedFriendAttendeesForDate)
                })
                
            })
            let _ = alert.addButton("Reject", action: {
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                FirebaseClient.acceptOrRejectInviteRequest(accepted: false, uniqueInvitationID: invitationRequest.inviteID, userID: appDelegate.user!.FBID, completion: { (success) in
                    if (!success) {
                        Utilities.printDebugMessage("Failure rejecting invite request")
                    }
                    else {
                        Utilities.printDebugMessage("Success rejecting invite request")
                    }
                    self.updateDataAndTableView({ (success) in
                        DispatchQueue.main.async {
                            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                        }
                    })

                })
            })
            if (fromUser.Name.components(separatedBy: " ").count != 0) {
                if let firstName = fromUser.Name.components(separatedBy: " ").first {
                    
                    var subtitle = ""
                    if let specialEventID = invitationRequest.specialEventID {
                        let eventName = appDelegate.specialEvents[specialEventID]!.EventName
                        subtitle = "\(fromUser.Name) invited you to go to \(eventName) at \(venue.VenueNickName) on \(DateUtilities.convertDateToStringByFormat(date: invitationRequest.date, dateFormat: DateUtilities.Constants.uiDisplayFormat))!"
                    } else {
                        subtitle = "\(fromUser.Name) invited you to go to \(venue.VenueNickName) on \(DateUtilities.convertDateToStringByFormat(date: invitationRequest.date, dateFormat: DateUtilities.Constants.uiDisplayFormat))!"
                    }
                    
                    _ = alert.showInfo("Invite from \(firstName)", subTitle: subtitle)
                }
            }
        }
        else {
            Utilities.printDebugMessage("Error: could not find user")
        }
        
        
    }
}
