//
//  RatingViewController.swift
//  PopupDialog
//
//  Created by Martin Wildfeuer on 11.07.16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MVHorizontalPicker

class PopupSubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    
    struct Constants {
        static let SECTION_TITLES = ["Live", "Planned"]
        static let LIVE_SECTION_ROW = 0
        static let PLANNED_SECTION_ROW = 1
        static let CELL_HEIGHT : CGFloat = 74.0
    }
    
    @IBOutlet weak var tableViewFrameView: UIView!
    @IBOutlet weak var datePicker: MVHorizontalPicker!
    @IBOutlet weak var venueImageView: UIImageView!
    weak var delegate: VenueDelegate?
    
    @IBOutlet weak var liveAttendeesLabel: UILabel!
    @IBOutlet weak var liveFriendsLabel: UILabel!
    @IBOutlet weak var plannedAttendeesLabel: UILabel!
    @IBOutlet weak var plannedFriendsLabel: UILabel!
    
    
    let INDEX_OF_PLANNED_ATTENDEES = 1
    let INDEX_OF_LIVE_ATTENDEES = 0
    var stringsOfUpcomingDays : [String] = [] // Full dates
    var imageCache = [String: UIImage]()
    //keys are yyyy-MM-dd
    var allFriendsForDate : [String : [[User]]] = [:]
    var allPlannedAttendeesForDateCountDict = [String : Int]()
    var allCurrentAttendeesForDateCountDict = 0
    var allPlannedFriendsForDateCountDict = [String : Int]()
    var allCurrentFriendsForDateCountDict = 0
    
    var tableView: UITableView  =   UITableView()
    
    var startDate : Date?
    
    func setStartDate(date : Date) {
        self.startDate = date
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let startDate = self.startDate {
            if(DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: startDate))) {
                let fullDate = DateUtilities.convertDateToStringByFormat(date: startDate, dateFormat: DateUtilities.Constants.fullDateFormat)
                if let startIndex = stringsOfUpcomingDays.index(of: fullDate) {
                    datePicker.setSelectedItemIndex(startIndex, animated: true)
                }
            }
        }
    }
    
    //Very hacky code:
    //    var overrideBool = false
    //    var newFrame : CGRect?
    //
    //    func fixHeightIfNecessary(maxHeight : CGFloat) {
    //        if self.view.frame.height > maxHeight {
    //            self.overrideBool = true
    //            self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: maxHeight - 300)
    //            newFrame =  CGRect(x: 0, y: 0, width: self.view.frame.width, height: maxHeight - 300)
    //            tableView.frame         =   tableViewFrameView.frame
    //            let frame = CGRect(x: tableViewFrameView.frame.minX, y: tableViewFrameView.frame.minY, width: tableViewFrameView.frame.width + 50.0, height: tableViewFrameView.frame.height)
    //            tableView.frame = frame
    //            tableView.delegate      =   self
    //            tableView.dataSource    =   self
    //
    //            tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
    //            setFriendsForVenueForDate(venue: delegate!.venueToPass!)
    //            setAttendButtonTitle()
    //            setLabelsForGraphic()
    //            self.view.addSubview(tableView)
    //
    //            self.view.setNeedsLayout()
    //            self.view.setNeedsDisplay()
    //            Utilities.printDebugMessage("ERROR: need to fix popup height")
    //
    //        }
    //    }
    //
    //    override func viewDidLayoutSubviews() {
    //
    //        super.viewDidLayoutSubviews()
    //        if (overrideBool) {
    //            if let newFrame = self.newFrame {
    //                self.view.frame = newFrame
    //                tableView.frame         =   tableViewFrameView.frame
    //                let frame = CGRect(x: tableViewFrameView.frame.minX, y: tableViewFrameView.frame.minY, width: tableViewFrameView.frame.width + 50.0, height: tableViewFrameView.frame.height)
    //                tableView.frame = frame
    //                self.view.layoutSubviews()
    //            }
    //        }
    //
    //    }
    
    override func viewDidLoad() {
        datePicker.titles = self.determineTitleOrder(dayCount: DateUtilities.Constants.NUMBER_OF_DAYS_TO_DISPLAY)
        datePicker.itemWidth = 100
        
        datePicker.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        datePicker.borderWidth = 1
        
        datePicker.tintColor = UIColor.black
        super.viewDidLoad()
        delegate?.retrieveImage(imageURL: (delegate?.venueToPass?.ImageURL)!, completion: { (image) in
            DispatchQueue.main.async {
                self.venueImageView.image = image
            }
        })
        
        //tableview
        tableView.frame         =   tableViewFrameView.frame
        let frame = CGRect(x: tableViewFrameView.frame.minX, y: tableViewFrameView.frame.minY, width: tableViewFrameView.frame.width + 50.0, height: tableViewFrameView.frame.height)
        tableView.frame = frame
        tableView.delegate      =   self
        tableView.dataSource    =   self
        
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
        setFriendsForVenueForDate(venue: delegate!.venueToPass!)
        setAttendButtonTitle()
        setLabelsForGraphic()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapDatePicker(_:)))
        self.datePicker.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        //self.datePicker.addGestureRecognizer(tap)
        
        self.view.addSubview(tableView)
    }
    
    func tapDatePicker(_ sender: UITapGestureRecognizer) {
        print("\(sender.location(in: datePicker))")
        print("Item Width: \(datePicker.itemWidth))")
        print("Frame Width: \(datePicker.frame.width)")
        
        if(sender.location(in: datePicker).x > (datePicker.frame.width + datePicker.itemWidth)/2 ) {
            Utilities.printDebugMessage("HI I SHOULD GO RIGHT NOW PLEASE!!")
            if(datePicker.selectedItemIndex < datePicker.titles.count - 1) {
                datePicker.setSelectedItemIndex(datePicker.selectedItemIndex + 1, animated: true)
            }
        } else if (sender.location(in: datePicker).x < (datePicker.frame.width - datePicker.itemWidth)/2) {
            Utilities.printDebugMessage("HI I SHOULD GO LEFT NOW PLEASE!!")
            if(datePicker.selectedItemIndex > 0) {
                datePicker.setSelectedItemIndex(datePicker.selectedItemIndex - 1, animated: true)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentDay = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        return friendsAttendingClubForDay[section].count
    }
    
    func tableView(_ cellForRowAttableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentDay = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        let friend = friendsAttendingClubForDay[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND")! as! VenueFriendTableViewCell
        cell.profilePic.makeViewCircle()
        cell.nameLabel.text = friend.Name
        let planCount = friend.Plans.count
        if(indexPath.section == Constants.LIVE_SECTION_ROW) {
            cell.subtitleLabel.text = "Currently Live"
        }
        else {
            cell.subtitleLabel.text = Utilities.setPlurality(string: "\(planCount) plan", count: planCount)
        }
        retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 25))
        //returnedView.backgroundColor = FlockColors.FLOCK_BLUE
        
        let gradient = CAGradientLayer()
        
        gradient.frame = returnedView.bounds
        
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [FlockColors.FLOCK_BLUE.cgColor, FlockColors.FLOCK_LIGHT_BLUE.cgColor]
        
        returnedView.layer.insertSublayer(gradient, at: 0)
        
        
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.size.width, height: 25))
        label.textColor = .white
        label.text = Constants.SECTION_TITLES[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    @IBAction func pickerValueChanged(_ sender: MVHorizontalPicker) {
        setAttendButtonTitle()
        setLabelsForGraphic()
        self.tableView.reloadData()
    }
    
    func setLabelsForGraphic() {
        let currentDay = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        self.liveFriendsLabel.text = Utilities.setPlurality(string: "\(self.allCurrentFriendsForDateCountDict) Live\nFriend", count: self.allCurrentFriendsForDateCountDict)
        self.liveAttendeesLabel.text = "\(self.allCurrentAttendeesForDateCountDict) Live\nTotal"
        self.plannedFriendsLabel.text = Utilities.setPlurality(string: "\(self.allPlannedFriendsForDateCountDict[currentDay]!) Planned\nFriend", count: self.allPlannedFriendsForDateCountDict[currentDay]!)
        self.plannedAttendeesLabel.text = "\(self.allPlannedAttendeesForDateCountDict[currentDay]!) Planned\nTotal"
        
    }
    
    func setAttendButtonTitle() {
        let venueString = self.delegate!.venueToPass!.VenueNickName.uppercased()
        let dateString = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        let date = DateUtilities.getDateFromString(date: dateString)
        let dateStringInFormat = DateUtilities.convertDateToStringByFormat(date: date, dateFormat: "MMMM d")
        
        var disable = false
        if let plannedUsersForDate = self.allFriendsForDate[dateString]?[INDEX_OF_PLANNED_ATTENDEES] {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            for user in plannedUsersForDate {
                Utilities.printDebugMessage("checking")
                if(user.FBID == appDelegate.user!.FBID) {
                    Utilities.printDebugMessage("disabling")
                    disable = true
                    break
                }
            }
        } else {
            disable = true
            Utilities.printDebugMessage("Something wrong with date dictionary - doesn't contain dateString")
        }
        
        
        self.delegate?.changeButtonTitle(title: "GO TO \(venueString) ON \(dateStringInFormat.uppercased())", shouldDisable: disable)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let currentDay = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        return friendsAttendingClubForDay.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    //Set the dictionary to use for tableview display, maps from full string dates to array of arrays of users
    func setFriendsForVenueForDate(venue : Venue ) {
        var allFriendsForDate : [String : [[User]]] = initializeAllDictionaries()
        let plannedAttendees = venue.PlannedAttendees
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let friends = appDelegate.friends
        let users = appDelegate.users
        for (_, plannedAttendee) in plannedAttendees {
            if let friend = friends[plannedAttendee] {
                for (visitID,plan) in friend.Plans {
                    if(DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        if(plan.venueID == venue.VenueID) {
                            let fullDate = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.fullDateFormat)
                            allFriendsForDate[fullDate]![self.INDEX_OF_PLANNED_ATTENDEES].append(friend)
                            
                            self.allPlannedFriendsForDateCountDict[fullDate]! += 1
                            self.allPlannedAttendeesForDateCountDict[fullDate]! += 1
                        }
                    } else {
                        friend.Plans[visitID] = nil
                    }
                }
            }
            else if let user = users[plannedAttendee] {
                for (_,plan) in user.Plans {
                    if(DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        if(plan.venueID == venue.VenueID) {
                            let fullDate = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.fullDateFormat)
                            
                            self.allPlannedAttendeesForDateCountDict[fullDate]! += 1
                        }
                    }
                }
            }
        }
        
        var liveUsers : [User] = []
        for (_, currentAttendee) in venue.CurrentAttendees {
            if let friend = friends[currentAttendee] {
                liveUsers.append(friend)
            }
        }
        self.allCurrentAttendeesForDateCountDict = venue.CurrentAttendees.count
        self.allCurrentFriendsForDateCountDict = liveUsers.count
        allFriendsForDate[DateUtilities.getTodayFullDate()]![INDEX_OF_LIVE_ATTENDEES] = liveUsers
        self.allFriendsForDate = allFriendsForDate
    }
    
    func initializeAllDictionaries() -> [String : [[User]]] {
        var plannedFriendsForDate : [String : [[User]]] = [:]
        for day in stringsOfUpcomingDays {
            plannedFriendsForDate[day] = [[],[]]
            allPlannedAttendeesForDateCountDict[day] = 0
            allPlannedFriendsForDateCountDict[day] = 0
        }
        return plannedFriendsForDate
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.CELL_HEIGHT
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
    
    // Determines the order for the day of the week by getting the current day, finding the index in
    // a standard week, and iterating through array
    func determineTitleOrder(dayCount : Int) -> [String] {
        var fullArray : [String] = []
        var dayOfWeekArray : [String] = []
        var date = Date()
        for _ in 0...(dayCount-1) {
            fullArray.append(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.fullDateFormat))
            dayOfWeekArray.append(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.dayOfWeekDateFormat))
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        self.stringsOfUpcomingDays = fullArray
        return dayOfWeekArray
    }
    
}
