//
//  RatingViewController.swift
//  PopupDialog
//
//  Created by Martin Wildfeuer on 11.07.16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MVHorizontalPicker

class PopupSubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    struct Constants {
        static let SECTION_TITLES = ["Live", "Planned"]
    }
    
    @IBOutlet weak var tableViewFrameView: UIView!
    @IBOutlet weak var datePicker: MVHorizontalPicker!
    @IBOutlet weak var venueImageView: UIImageView!
    weak var delegate: VenueDelegate?
    
    let NUMBER_OF_DAYS_TO_DISPLAY = 7
    let INDEX_OF_PLANNED_ATTENDEES = 1
    let INDEX_OF_LIVE_ATTENDEES = 0
    var stringsOfUpcomingDays : [String] = [] // Full dates
    var imageCache = [String: UIImage]()
    //keys are yyyy-MM-dd
    var allFriendsForDate : [String : [[User]]] = [:]

    var tableView: UITableView  =   UITableView()
    
    override func viewDidLoad() {
        datePicker.titles = self.determineTitleOrder(dayCount: NUMBER_OF_DAYS_TO_DISPLAY)
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
        tableView.delegate      =   self
        tableView.dataSource    =   self
        
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
        setFriendsForVenueForDate(venue: delegate!.venueToPass!)
        self.view.addSubview(tableView)
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
        cell.nameLabel.text = friend.Name
        retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic)
        return cell
    }
    
    @IBAction func pickerValueChanged(_ sender: MVHorizontalPicker) {
        self.tableView.reloadData()
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
        var allFriendsForDate : [String : [[User]]] = initializePlanDictionary()
        let plannedAttendees = venue.PlannedAttendees
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let friends = appDelegate.friends
        Utilities.printDebugMessage("1")
        for (_, plannedAttendee) in plannedAttendees {
            Utilities.printDebugMessage("2")
            if let friend = friends[plannedAttendee] {
                Utilities.printDebugMessage("3")
                for (_,plan) in friend.Plans {
                    Utilities.printDebugMessage("4")
                    if(plan.venueID == venue.VenueID && isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        let fullDate = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.fullDateFormat)
                        allFriendsForDate[fullDate]![self.INDEX_OF_PLANNED_ATTENDEES].append(friend)
                        Utilities.printDebugMessage("5")
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
        allFriendsForDate[DateUtilities.getTodayFullDate()]![INDEX_OF_LIVE_ATTENDEES] = liveUsers
        self.allFriendsForDate = allFriendsForDate
    }
    
    func initializePlanDictionary() -> [String : [[User]]]{
        var plannedFriendsForDate : [String : [[User]]] = [:]
        for day in stringsOfUpcomingDays {
            plannedFriendsForDate[day] = [[],[]]
        }
        return plannedFriendsForDate
    }
    
    
    
    func isValidTimeFrame(dayDiff: Int) -> Bool {
        return (dayDiff >= 0 && dayDiff < NUMBER_OF_DAYS_TO_DISPLAY)
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
