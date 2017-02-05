//
//  TestingViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import SCLAlertView

class TestingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //The most recently selected venueName, or empty string if none
    var venueName : String = ""
    
    //Add a Venue
    @IBAction func createViewButtonPressed(_ sender: Any) {
        let alert = SCLAlertView()
        let txt = alert.addTextField("Enter your name")
        alert.addButton("Upload Venue Image and Create Venue") {
            if (txt.text != nil) && txt.text! != "" {
                self.venueName = txt.text!
                Utilities.presentImagePicker(vc: self, vcDelegate: self)
            }
            else {
                Utilities.printDebugMessage("Error with Venue Name")
            }
            
        }
        alert.showEdit("Create Venue", subTitle: "Enter Venue Information")
    }
    
    //An image was chosen
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //we selected an image
        dismiss(animated: true, completion: nil)
        handleImageSelectedForInfo(info as [String : AnyObject])
    }
    
    //If an acceptable image was selected, upload it to firebase
    fileprivate func handleImageSelectedForInfo(_ info: [String: AnyObject]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabBarViewController = appDelegate.simpleTBC!
        let loadingScreen = Utilities.presentLoadingScreen(vcView: tabBarViewController.view)
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            FirebaseClient.uploadToFirebaseStorageUsingImage(selectedImage, completion: { (imageUrl) in
                Utilities.printDebugMessage("Picture uploaded and URL added to Update URL")
                if let imageUrl = imageUrl {
                    FirebaseClient.addVenue(self.venueName, imageURL: imageUrl, logoURL: imageUrl, completion: { (status) in
                        if (status) {
                            Utilities.printDebugMessage("Added Venue Successfully")
                        }
                        else {
                            Utilities.printDebugMessage("Error adding Venue")
                        }
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: tabBarViewController.view)
                    })
                }
                else {
                    Utilities.printDebugMessage("Error uploading image")
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: tabBarViewController.view)
                }
                
            })
        }
        else {
            Utilities.printDebugMessage("Error uploading image")
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: tabBarViewController.view)

        }
    }

    @IBAction func createUser(_ sender: Any) {
        let alert = SCLAlertView()
        let txtName = alert.addTextField("Enter your name")
        let txtFBID = alert.addTextField("Enter your FBID")
        let txtPicURL = alert.addTextField("Enter your picture URL")
        alert.addButton("Create User") {
            if(txtName.text! != "" && txtFBID.text! != "" && txtPicURL.text! != "") {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            LoginClient.createUser(name: txtName.text!, FBID: txtFBID.text!, pictureURL: txtPicURL.text!, completion: { (success) in
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                if(success) {
                    Utilities.printDebugMessage("User Created")
                } else {
                    Utilities.printDebugMessage("User NOT Created")
                }
            })
            }
        }
        alert.showEdit("Create User", subTitle: "Enter User Info")

    }
    
    @IBAction func updateAppPressed(_ sender: Any) {
        let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            if (!success) {
                Utilities.printDebugMessage("Error updating app")
            }
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
        }
        
        
    }

    @IBAction func sendFriendRequestPressed(_ sender: Any) {
        let alert = SCLAlertView()
        let txtFromID = alert.addTextField("Enter fromID")
        let txtToID = alert.addTextField("Enter toID")
        alert.addButton("Send Friend Request") {
            if(txtFromID.text! != "" && txtToID.text! != "") {
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                FirebaseClient.sendFriendRequest(txtFromID.text!, toID: txtToID.text!, completion: { (success) in
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                    if(success) {
                        Utilities.printDebugMessage("Request sent")
                    } else {
                        Utilities.printDebugMessage("Request NOT sent")
                    }
                })
            }
        }
        alert.showEdit("Send Friend Request", subTitle: "Type to/from IDs")
        
    }
   
    @IBAction func confirmFriendRequestPressed(_ sender: Any) {
        let alert = SCLAlertView()
        let txtFromID = alert.addTextField("Enter fromID")
        let txtToID = alert.addTextField("Enter toID")
        alert.addButton("Send Friend Request") {
            if(txtFromID.text! != "" && txtToID.text! != "") {
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                FirebaseClient.confirmFriendRequest(txtFromID.text!, toID: txtToID.text!, completion: { (success) in
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                    if(success) {
                        Utilities.printDebugMessage("Request confirmed")
                    } else {
                        Utilities.printDebugMessage("Request NOT confirmed")
                    }
                })
            }
        }
        alert.showEdit("Confirm Friend Request", subTitle: "Type to/from IDs")
    }

}
