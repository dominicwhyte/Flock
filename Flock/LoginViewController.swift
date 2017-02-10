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

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var loginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.delegate = self
        loginButton.center = self.view.center
        loginButton.readPermissions = ["public_profile", "user_friends", "email"]
        // Do any additional setup after loading the view.
        
        //Autologin functionality
        
        if (FBSDKAccessToken.current() != nil) {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.masterLogin(completion: { (success) in
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                if (success) {
                    Utilities.printDebugMessage("Successfully auto logged in")
                    self.performSegue(withIdentifier: "LOGIN_IDENTIFIER", sender: nil)
                }
                else {
                    Utilities.printDebugMessage("Error with auto login")
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.loginButton.isHidden = true
        
        if error != nil
        {
            print(error.localizedDescription)
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
        }
            
        else if result.isCancelled
        {
            self.loginButton.isHidden = false
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
        }
            
        else
        {
            //Block login until .login returns
            //Calling login will change the state of FIRAuth.auth(), thus initiating the launch sequence from viewdidload
            LoginClient.login({ (status) in
                if (status) {
                    appDelegate.masterLogin(completion: { (loginStatus) in
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                        if(loginStatus) {
                            Utilities.printDebugMessage("Successful login")
                            self.performSegue(withIdentifier: "LOGIN_IDENTIFIER", sender: nil)
                        }
                        else {
                            Utilities.printDebugMessage("Unsucessful login")
                        }
                    })
                }
                else {
                    Utilities.printDebugMessage("Error logging in, login() returned false")
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                }
            })
            
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        LoginClient.logout()
    }

    

    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabVC = segue.destination as? SimpleTabBarController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.simpleTBC = tabVC
        }
    }
    

}
