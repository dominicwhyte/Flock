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
        static let CELL_HEIGHT : CGFloat = 74.0
    }
    
    @IBOutlet weak var tableViewFrameView: UIView!
    @IBOutlet weak var datePicker: MVHorizontalPicker!
    @IBOutlet weak var venueImageView: UIImageView!
    weak var delegate: VenueDelegate?
    
    @IBOutlet weak var liveLabel: UILabel!
    
    let INDEX_OF_PLANNED_ATTENDEES = 1
    let INDEX_OF_LIVE_ATTENDEES = 0
    var stringsOfUpcomingDays : [String] = [] // Full dates
    var imageCache = [String: UIImage]()
    //keys are yyyy-MM-dd
    var allFriendsForDate : [String : [[User]]] = [:]
    
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
    
    override func viewDidLoad() {
        datePicker.titles = self.determineTitleOrder(dayCount: DateUtilities.Constants.NUMBER_OF_DAYS_TO_DISPLAY)
        datePicker.itemWidth = 100
        
        datePicker.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        datePicker.borderWidth = 1
        
        datePicker.tintColor = FlockColors.FLOCK_GRAY
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
        self.view.addSubview(tableView)
        setAttendButtonTitle()
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
        self.tableView.reloadData()
    }
    
    func setAttendButtonTitle() {
        let venueString = self.delegate!.venueToPass!.VenueName.uppercased()
        let dateString = self.stringsOfUpcomingDays[datePicker.selectedItemIndex]
        let date = DateUtilities.getDateFromString(date: dateString)
        let dateStringInFormat = DateUtilities.convertDateToStringByFormat(date: date, dateFormat: "MMMM d")
        self.delegate?.changeButtonTitle(title: "ATTEND \(venueString) ON \(dateStringInFormat)")
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
        for (_, plannedAttendee) in plannedAttendees {
            if let friend = friends[plannedAttendee] {
                for (_,plan) in friend.Plans {
                    if(plan.venueID == venue.VenueID && DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        let fullDate = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.fullDateFormat)
                        allFriendsForDate[fullDate]![self.INDEX_OF_PLANNED_ATTENDEES].append(friend)
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
