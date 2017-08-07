//
//  SecondaryAdminViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 08/04/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class SecondaryAdminViewController: UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    @IBOutlet weak var eventsPicker: UIPickerView!
    var specialEvents = [Event]()
    var chosenEventIndex = 0
    @IBOutlet weak var hackCount: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hackCount.attributedPlaceholder = NSAttributedString(string: "Number of Users")
        eventsPicker.dataSource = self
        eventsPicker.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for (_,event) in appDelegate.specialEvents {
            if (DateUtilities.dateIsWithinValidTimeframe(date: event.EventStart)) {
                
                specialEvents.append(event)
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return specialEvents.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venueName = appDelegate.venues["VenueID"]!.VenueName
        let eventName = specialEvents[row].EventName
        return "\(eventName) (\(venueName))"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        chosenEventIndex = row
    }
    
    //the idea: use a random uuid for the events page, and then use John Smith for the places page
    @IBAction func growthHack(_ sender: UIButton) {
        if let count:Int = Int(hackCount.text!) {
            growthHack(numTimes: count)
            for i in 0..<count {
            }
        }
        else {
            Utilities.shakeView(sender)
        }
    }
    
    func growthHack(numTimes:Int) {
        if (numTimes <= 0) {
            return
        }
        else {
            let event = specialEvents[chosenEventIndex]
            let randomGHID = "GH" + UUID().uuidString
            FirebaseClient.ghAddUserToVenuePlansForDate(date: DateUtilities.getStringFromDate(date: event.EventStart), venueID: "VenueID", randomUserID : randomGHID, userID: "160916481072667", add: true, specialEventID: event.EventID, completion: { (success) in
                if (success) {
                    Utilities.printDebugMessage("Successfully made plan to go to event")
                    self.growthHack(numTimes: numTimes - 1)
                }
                else {
                    Utilities.printDebugMessage("Error making plan to go to event (event deleted?)")
                }
            })

        }
    }
    
    
    
}
