//
//  LoginViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 02/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import SimpleTab
import AASquaresLoading
import PermissionScope

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, BWWalkthroughViewControllerDelegate {
    let multiPscope = PermissionScope()

    @IBOutlet weak var loginButton: FBSDKLoginButton!
    var loadingSquare : AASquaresLoading?
    
    @IBOutlet weak var flockLogo: UIImageView!
    @IBOutlet weak var loadingSquareScreenView: UIView!
    
    @IBOutlet weak var walkThroughButton: UIButton!
    let SECONDS_UNTIL_ABORT_LOGIN = 1
    
    override func viewDidLoad() {
        walkThroughButton.layer.borderWidth = 1
        walkThroughButton.layer.borderColor = UIColor.white.cgColor
        walkThroughButton.layer.cornerRadius = 3
        walkThroughButton.layer.masksToBounds = true
        flockLogo.alpha = 0
        PermissionUtilities.setupPermissionScope(permissionScope: multiPscope)
        
        loadingSquare = AASquaresLoading(target: self.loadingSquareScreenView, size: 40)
        loadingSquareScreenView.isHidden = true
        
        super.viewDidLoad()
        if (FBSDKAccessToken.current() != nil) {
            hideButtons(hidden: true)
        }
        else {
            hideButtons(hidden: false)
        }
        loginButton.delegate = self
        loginButton.center = self.view.center
        loginButton.readPermissions = ["public_profile", "user_friends", "email"]
        self.view!.addSubview(loginButton)
        loginButton.alpha = 0
        walkThroughButton.alpha = 0
        
        // Do any additional setup after loading the view.
        //Utilities.setUnderlinedTextAttribute(text: "Terms and Conditions", button: termsAndConditionsLabel)
        
        
        setGradientBackground()
        //Autologin functionality
        
        if (FBSDKAccessToken.current() != nil) {
            setUIForLogin()
            //C
            var userNotRetrieved = true
            //Flawed implementation - leads to crashes since login thread is not killed
//            let deadlineTime = DispatchTime.now() + .seconds(SECONDS_UNTIL_ABORT_LOGIN)
//            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
//                if (userNotRetrieved) {
//                    Utilities.printDebugMessage("Abandon loading")
//                    LoginClient.logout(vc: self)
//                    self.resetUIForCancelledLogin()
//                }
//            })
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.masterLogin(completion: { (success) in
                userNotRetrieved = false
                if (success) {
                    Utilities.printDebugMessage("Successfully auto logged in")
                    self.performSegue(withIdentifier: "LOGIN_IDENTIFIER", sender: nil)
                }
                else {
                    Utilities.printDebugMessage("Error with auto login")
                    LoginClient.logoutBackend()
                    DispatchQueue.main.async {
                        self.resetUIForCancelledLogin()
                    }
                }
            })
        }
        //Request permissions
        else {
            
            //show walkthrough if not yet shown
            let userDefaults = UserDefaults.standard
            
            if !userDefaults.bool(forKey: "walkthroughPresented") {
                Utilities.showWalkthrough(vcDelegate: self, vc: self)
                
                userDefaults.set(true, forKey: "walkthroughPresented")
                userDefaults.synchronize()
            }
        }
    }
    
    func walkthroughPageDidChange(_ pageNumber: Int) {
        print("Current Page \(pageNumber)")
    }
    
    func walkthroughCloseButtonPressed() {
        self.dismiss(animated: true, completion: nil)
        
        PermissionUtilities.getPermissionsIfDenied(permissionScope: multiPscope)
    }
    
    
    func hideButtons(hidden : Bool) {
        walkThroughButton.isHidden = hidden
        loginButton.isHidden = hidden
    }
    
    @IBAction func walkthroughButtonPressed(_ sender: Any) {
        Utilities.showWalkthrough(vcDelegate: self, vc: self)
    }
    
    
    
    func setGradientBackground() {
        let colorTop =  UIColor.white.cgColor
        let colorBottom = UIColor.black.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setUIForLogin() {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = false
            self.hideButtons(hidden: true)
            
            self.loadingSquareScreenView.isHidden = false
            self.loadingSquare!.isHidden = false
            self.loadingSquare!.color = UIColor.white
            self.loadingSquare!.backgroundColor = UIColor.clear
            self.loadingSquare!.start()
        }
    }
    
    func resetUIForCancelledLogin() {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = true
            self.hideButtons(hidden: false)
            
            self.loadingSquareScreenView.isHidden = true
            self.loadingSquare!.isHidden = true
            self.loadingSquare!.color = UIColor.white
            self.loadingSquare!.backgroundColor = UIColor.clear
            self.loadingSquare!.stop()
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginButton.fadeIn()
        flockLogo.fadeIn()
        walkThroughButton.fadeIn()
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        setUIForLogin()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if error != nil
        {
            print(error.localizedDescription)
            resetUIForCancelledLogin()
        }
            
        else if result.isCancelled
        {
            self.hideButtons(hidden: false)
            resetUIForCancelledLogin()
        }
            
        else
        {
            //Block login until .login returns
            //Calling login will change the state of FIRAuth.auth(), thus initiating the launch sequence from viewdidload
            LoginClient.login({ (status) in
                if (status) {
                    appDelegate.masterLogin(completion: { (loginStatus) in
                        if(loginStatus) {
                            Utilities.printDebugMessage("Successful login")
                            self.performSegue(withIdentifier: "LOGIN_IDENTIFIER", sender: nil)
                        }
                        else {
                            Utilities.printDebugMessage("Unsucessful login")
                            LoginClient.logoutBackend()
                            
                        }
                        DispatchQueue.main.async {
                            self.resetUIForCancelledLogin()
                        }
                    })
                }
                else {
                    Utilities.printDebugMessage("Error logging in, login() returned false")
                    
                    self.resetUIForCancelledLogin()
                }
            })
            
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        LoginClient.logout(vc: self)
    }

    

    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabVC = segue.destination as? SimpleTabBarController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.simpleTBC = tabVC
            
            // Setup Badges
            var totalUnread = 0
            for (_, count) in appDelegate.unreadMessageCount {
                totalUnread += count
            }
            if let stb = appDelegate.simpleTBC {
                if totalUnread > 0 {
                    stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                } else {
                    stb.removeAllBadges()
                }
            }
        }
    }
    

}

extension UIView {
    func fadeIn(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 3.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
    
    func fadeOutPartially(_ duration: TimeInterval = 2.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions.curveLinear, animations: {
            self.alpha = 0.4
        }, completion: completion)
    }
}
