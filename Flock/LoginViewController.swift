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
        loginButton.readPermissions = ["public_profile", "user_friends"]
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.loginButton.isHidden = true
        
        if error != nil
        {
            print(error.localizedDescription)
        }
            
        else if result.isCancelled
        {
            self.loginButton.isHidden = false
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
                        }
                    })
                }
                else {
                    Utilities.printDebugMessage("Error logging in, login() returned false")
                }
            })
            //self.performSegue(withIdentifier: "loggedIn", sender: nil)
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
