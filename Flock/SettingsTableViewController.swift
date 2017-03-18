//
//  SettingsTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 18/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import Instabug

class SettingsTableViewController: UITableViewController {

    struct Constants {
        static let SECTION_TITLES = ["Profile", "Support", "More Info"]
    }
    
    
    @IBOutlet var backgroundViewCollection: [UIView]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        
        for backgroundViewInstance in backgroundViewCollection {
            setGradientBackground(aView: backgroundViewInstance)
            setShadow(aView: backgroundViewInstance)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        aView.layer.shadowOpacity = 0.7
        //aView.layer.shadowOffset = CGSize(width: 0, height: 3)
        aView.layer.shadowRadius = 3
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
    
    
   }
