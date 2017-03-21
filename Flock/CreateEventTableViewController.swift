//
//  CreateEventTableViewController.swift
//
//
//  Created by Dominic Whyte on 20/03/17.
//
//

import UIKit

class CreateEventTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource,UIPickerViewDelegate {
    
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var venuePicker: UIPickerView!
    var imageURL : String?
    var pickerVenueNames = [String]()
    var pickerVenuesIDs = [String]()
    
    @IBOutlet weak var submitButton: UIButton!
    
    
    @IBOutlet weak var specialEventSwitch: UISwitch!
    var chosenVenueIndex = 0
    
    override func viewDidLoad() {
        venuePicker.dataSource = self
        venuePicker.delegate = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for (_,venue) in appDelegate.venues {
            pickerVenuesIDs.append(venue.VenueID)
            pickerVenueNames.append(venue.VenueName)
        }
        assert(pickerVenueNames.count == pickerVenuesIDs.count)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerVenueNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerVenueNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        chosenVenueIndex = row
    }
    
    
    @IBAction func chooseImagePressed(_ sender: Any) {
        Utilities.presentImagePicker(vc: self, vcDelegate: self)
    }
    
    @IBAction func createEvent(_ sender: Any) {
        if (eventName.text == nil || eventName.text! == "") {
            
        }
        else {
            let chosenVenueID = pickerVenuesIDs[chosenVenueIndex]
            let chosenEventName = eventName.text!
            let chosenDateString = DateUtilities.getStringFromDate(date: datePicker.date)
            let optionalImageURL = imageURL
            let isSpecialEvent = specialEventSwitch.isOn
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            FirebaseClient.uploadEvent(chosenVenueID, chosenEventName: chosenEventName, chosenDateString: chosenDateString, optionalImageURL: optionalImageURL, isSpecialEvent: isSpecialEvent) { (success) in
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                if (success) {
                    Utilities.printDebugMessage("Successfully added venue")
                    self.navigationController!.popViewController(animated: true)
                }
                else {
                    Utilities.printDebugMessage("Failed to add venue")
                    Utilities.shakeView(self.submitButton)
                }
                
            }

        }
        
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
                self.imageURL = imageUrl
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: tabBarViewController.view)
            })
        }
        else {
            Utilities.printDebugMessage("Error uploading image")
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: tabBarViewController.view)
            
        }
    }
    
    
    
}
