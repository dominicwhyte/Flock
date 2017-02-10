//
//  ProfileViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 08/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation
import UIKit
import LFTwitterProfile



class ProfileViewController: TwitterProfileViewController {

    struct Constants {
        static let SECTION_TITLES = ["Plans"]
        static let CELL_HEIGHT = 75
    }
    
    var tableView: UITableView!
    
    var custom: UIView!
    var label: UILabel!
    var user: User?
    var plans: [Plan] = [Plan]()
    
    
    override func numberOfSegments() -> Int {
        return 1
    }
    
    override func segmentTitle(forSegment index: Int) -> String {
        return "Segment \(index)"
    }
    
    override func prepareForLayout() {
        // TableViews
        self.tableView = UITableView(frame: CGRect.zero, style: .plain)
        
        self.setupTables()
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.SECTION_TITLES.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationString = "Hong Kong"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (self.user == nil || self.user!.FBID == appDelegate.user!.FBID) {
            setupUser(user: appDelegate.user!)
        } else {
            setupUser(user: user!)
        }
    }
    
    func setupUser(user : User) {
        self.user = user
        self.username = user.Name
        self.plans = Array(user.Plans.values)
        FirebaseClient.getImageFromURL(user.PictureURL) { (image) in
            DispatchQueue.main.async {
                self.profileImage = image
            }
        }

    
    }
    
    override func scrollView(forSegment index: Int) -> UIScrollView {
        return tableView
    }

}

// MARK: UITableViewDelegates & DataSources
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTables() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.user!.Plans.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plan = plans[indexPath.row]
        Utilities.animateToPlacesTabWithVenueIDandDate(venueID: plan.venueID, date: plan.date)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let plan = self.plans[indexPath.row]
        let venue = appDelegate.venues[plan.venueID]!
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND", for: indexPath) as! VenueFriendTableViewCell
        cell.nameLabel.text = venue.VenueName
        cell.subtitleLabel.text = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: "MMMM d")
        cell.profilePic.image = appDelegate.venueImages[venue.ImageURL]
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.CELL_HEIGHT)
    }
}

