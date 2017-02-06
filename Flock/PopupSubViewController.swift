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
    
    @IBOutlet weak var tableViewFrameView: UIView!
    @IBOutlet weak var datePicker: MVHorizontalPicker!
    @IBOutlet weak var venueImageView: UIImageView!
    weak var delegate: VenueDelegate?
    let NUMBER_OF_DAYS_TO_DISPLAY = 7
    var stringsOfUpcomingDays : [String] = []
    let daysOfWeek = [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" ]
    var imageCache = [String: UIImage]()
    //keys are yyyy-MM-dd
    var allFriendsForDate : [String : [[User]]] = [:]

    var tableView: UITableView  =   UITableView()
    
    override func viewDidLoad() {
        datePicker.titles = self.determineTitleOrder()
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
        let currentDay = datePicker.titles[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        return friendsAttendingClubForDay[section].count
    }
    
    func tableView(_ cellForRowAttableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentDay = datePicker.titles[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        let friend = friendsAttendingClubForDay[indexPath.section][indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND")! as! VenueFriendTableViewCell
        
        
        cell.nameLabel.text = friend.Name
        retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let currentDay = datePicker.titles[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        return friendsAttendingClubForDay.count
    }
    
    func setFriendsForVenueForDate(venue : Venue ) {
        var plannedFriendsForDate : [String : [[User]]] = initializePlanDictionary()
        let plannedAttendees = venue.PlannedAttendees
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let friends = appDelegate.friends
        for (_, plannedAttendee) in plannedAttendees {
            if let friend = friends[plannedAttendee] {
                for (_,plan) in friend.Plans {
                    if(plan.venueID == venue.VenueID && isValidTimeFrame(dayDiff: daysUntilPlan(planDate: plan.date))) {
                        let dayOfWeek = self.convertDateToDayOfWeek(date: plan.date)
                        plannedFriendsForDate[dayOfWeek]![1].append(friend)
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
        plannedFriendsForDate[self.getDayOfWeek()]![0] = liveUsers
        self.allFriendsForDate = plannedFriendsForDate
    }
    
    func initializePlanDictionary() -> [String : [[User]]]{
        var plannedFriendsForDate : [String : [[User]]] = [:]
        for day in daysOfWeek {
            plannedFriendsForDate[day] = [[],[]]
        }
        return plannedFriendsForDate
    }
    
    func daysUntilPlan(planDate: Date) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayAndMonth = cal.dateComponents([.day, .month], from: planDate)
        let nextBirthDay = cal.nextDate(after: today, matching: dayAndMonth,
                                        matchingPolicy: .nextTimePreservingSmallerComponents)!
        
        let diff = cal.dateComponents([.day], from: today, to: nextBirthDay)
        return diff.day!
    }
    
    func isValidTimeFrame(dayDiff: Int) -> Bool {
        return (dayDiff >= 0 && dayDiff < self.daysOfWeek.count)
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
    func determineTitleOrder() -> [String] {
        let currentDayOfWeek = self.getDayOfWeek()
        let currentIndex = daysOfWeek.index(of: currentDayOfWeek)
        var datePickerTitles : [String] = []
        let daysOfWeekCount = daysOfWeek.count
        for index in 0...(daysOfWeekCount-1) {
            datePickerTitles.append(daysOfWeek[(currentIndex! + index) % daysOfWeekCount])
        }
        return datePickerTitles
    }
    
    func setStringsOfUpcomingDays() {
        let calendar = NSCalendar.current
        let startDate = Date()
        let endDate =
        let dateRange = calendar.dateRange(startDate: startDate,
                                           endDate: endDate,
                                           stepUnits: .Day,
                                           stepValue: 1)
        
        for date in dateRange {
            print("It's \(date)!")
        }
        
        var date = Date()
        for index in 0...(NUMBER_OF_DAYS_TO_DISPLAY-1) {

            date = NSCalendar.current.date(byAdding: DateComponents., to: date)!

            stringsOfUpcomingDays.append()
        }
    }
    
    // Gets the current day of the week
    func getDayOfWeek() -> String {
        let date = Date()
        return self.convertDateToDayOfWeek(date: date)
    }
    
    func convertDateToDayOfWeek(date : Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.string(from: date)
        return dayOfWeekString
    }
   
}
