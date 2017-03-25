//
//  SettingsTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 18/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import Instabug
import SCLAlertView
import CoreLocation
import Social

class SettingsTableViewController: UITableViewController {

    struct Constants {
        static let SECTION_TITLES = ["Profile", "Support", "More Info"]
        static let ADMINS = ["10212248821081735", "1569272013102770"]
    }
    
    @IBOutlet weak var adminButton: UIButton!
    
    @IBOutlet var backgroundViewCollection: [UIView]!
    
    @IBOutlet weak var autoLiveSwitch: UISwitch!
    
    @IBOutlet weak var profileNameLabel: UILabel!
    
    
    override func viewDidLoad() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        profileNameLabel.text = appDelegate.user!.Name
        adminButton.isEnabled = false
        adminButton.isHidden = true
        
        super.viewDidLoad()
        autoLiveSwitch.backgroundColor = UIColor.white
        autoLiveSwitch.layer.cornerRadius = 16
        autoLiveSwitch.setOn((CLLocationManager.authorizationStatus() == .authorizedAlways), animated: false)
        
        self.tableView.separatorStyle = .none
        
        for backgroundViewInstance in backgroundViewCollection {
            setGradientBackground(aView: backgroundViewInstance)
            setShadow(aView: backgroundViewInstance)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (Constants.ADMINS.contains(appDelegate.user!.FBID)) {
            adminButton.isEnabled = true
            adminButton.isHidden = false
        }
        else {
            adminButton.isEnabled = false
            adminButton.isHidden = true
        }
        super.viewWillAppear(animated)
        let nav = self.navigationController?.navigationBar
        nav?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }

    func setGradientBackground(aView : UIView) {
        let gradient = CAGradientLayer()
        
        gradient.frame = aView.bounds
        
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [FlockColors.FLOCK_BLUE.cgColor, FlockColors.FLOCK_LIGHT_BLUE.cgColor]
        
        aView.layer.insertSublayer(gradient, at: 0)
    }
    
    func setShadow(aView : UIView) {
        aView.layer.shadowColor = UIColor.black.cgColor
        aView.layer.shadowOpacity = 0.4
        //aView.layer.shadowOffset = CGSize(width: 0, height: 3)
        aView.layer.shadowRadius = 1.5
        aView.layer.shadowPath = UIBezierPath(rect: aView.bounds).cgPath
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = FlockColors.FLOCK_BLUE
        header.textLabel?.font = UIFont(name: "OpenSans-Semibold", size: 18)
        header.textLabel?.text = Constants.SECTION_TITLES[section]
        header.textLabel?.frame = header.frame
        header.textLabel?.textAlignment = NSTextAlignment.left
        let backgroundView = UIView(frame: view.frame)
        backgroundView.backgroundColor = UIColor.white
        header.alpha = 1
        header.backgroundView = backgroundView
        
    }
    
    @IBAction func problemReportPressed(_ sender: Any) {
        Utilities.printDebugMessage("problem reported")
        Instabug.invoke(with: .newBug)
    }
    
    @IBAction func requestFeaturePressed(_ sender: Any) {
        Instabug.invoke(with: .newFeedback)
    }
    
    @IBAction func privacyPolicyPressed(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: "https://github.com/dominicwhyte/Flock-Privacy-Policy/blob/master/Private-Policy.pdf")!)
    }
    
    
    
    var ignoreSwitch = false
    
    @IBAction func autoLiveSwitchTriggered(_ sender: UISwitch) {
        
        if (!ignoreSwitch) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let newStatus = sender.isOn
            ignoreSwitch = true
            autoLiveSwitch.setOn(!newStatus, animated: false)
            if (!newStatus) {
                let alert = SCLAlertView()
                let _ = alert.addButton("Disable Auto-Live", action: {
                    if (CLLocationManager.authorizationStatus() == .notDetermined) {
                        Utilities.printDebugMessage("Error: auto-live wasn't on")
                        appDelegate.locationManager.requestWhenInUseAuthorization()
                        self.autoLiveSwitch.setOn(false, animated: true)
                    }
                    else {
                        let alert = SCLAlertView()
                        let _ = alert.addButton("Settings", action: {
                            self.autoLiveSwitch.setOn(false, animated: true)
                            UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
                        })
                        _ = alert.showInfo("Disabling auto-live", subTitle: "To disable auto-live, simply switch your location permissions from \"Always\" to \"While Using the App\" in your Settings")
                    }
                })
                _ = alert.showInfo("Disable auto-live?", subTitle: "Auto-live let's you go live at a Venue without even having to open the app, letting your flock know where you are so they can join in on the fun. Flock only uses your location when your device is already checking it, meaning that there is no additional drain to your battery.")
            }
            else {
                let alert = SCLAlertView()
                let _ = alert.addButton("Enable Auto-Live", action: {
                    if (CLLocationManager.authorizationStatus() == .notDetermined) {
                        appDelegate.locationManager.requestAlwaysAuthorization()
                        self.autoLiveSwitch.setOn(true, animated: true)
                    }
                    else if (CLLocationManager.authorizationStatus() == .authorizedAlways) {
                        Utilities.printDebugMessage("Error: auto-live already on")
                       self.autoLiveSwitch.setOn(true, animated: true)
                    }
                    //Need to go to settings to turn on auto-live
                    else {
                        let alert = SCLAlertView()
                        let _ = alert.addButton("Settings", action: {
                            self.autoLiveSwitch.setOn(true, animated: true)
                            UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
                        })
                        _ = alert.showInfo("Enabling auto-live", subTitle: "To enable auto-live, simply switch your location permissions to \"While Using the App\" in your Settings")
                    }

                })
                _ = alert.showInfo("Enable auto-live?", subTitle: "Auto-live let's you go live at a Venue without even having to open the app, letting your flock know where you are so they can join in on the fun. Flock only uses your location when your device is already checking it, meaning that there is no additional drain to your battery.")
            }
        }
        else {
            ignoreSwitch = false
        }
        
    }
    
    
    @IBAction func showWalkthroughPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.simpleTBC!.animateToTab(1, completion: { (navCon) in
            if let navCon = navCon as? UINavigationController {
                let vc = navCon.topViewController as! PeopleTableViewController
                vc.tableView.setContentOffset(CGPoint.zero, animated: true)

                    
                    

                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                viewController.alpha = 0.5
                
                appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
            }
            
        })
        
        
    }
    
    
    @IBAction func shareOnFacebookPressed(_ sender: Any) {
        let vc = SLComposeViewController(forServiceType:SLServiceTypeFacebook)
        
        vc?.add(URL(string: "https://itunes.apple.com/us/app/flock-find-your-flock/id1211976124?mt=8"))
        self.present(vc!, animated: true, completion: nil)
    }
    
    
   }
