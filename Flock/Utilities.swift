import UIKit
import Social
import MobileCoreServices
import AASquaresLoading
import Foundation
import SystemConfiguration
import OneSignal

struct FlockColors {
    static let FLOCK_BLUE = UIColor(red: 76/255, green: 181/255, blue: 245/255, alpha: 1.0)
    static let FLOCK_GRAY = UIColor(red: 183/255, green: 184/255, blue: 182/255, alpha: 1.0)
    static let FLOCK_LIGHT_BLUE = UIColor(red: 129/255, green: 202/255, blue: 247/255, alpha: 1.0)
    static let FLOCK_GOLD = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
}


class Utilities {
    
    
    
    struct Constants {
        static let notificationName = Notification.Name("reloadTableView")
        static let CONGRATULATORY_WORDS_LIST = ["Awesome!", "Phenomenal!", "Hot dog!", "Terrific!", "Marvelous!", "Wonderful!", "Sensational!", "Superb!", "Sublime!", "Brilliant!", "Peachy!", "Splendiferous!", "Outstanding!", "Legendary!"]
        static let SMALL_IPHONES = ["iPhone 5", "iPhone 5s", "iPhone 5c"]
        static let PARTY_IMAGES = ["party1", "party2", "party3", "party4"]
    }
    
    static func applyVerticalGradient(aView : UIView, colorTop : UIColor, colorBottom : UIColor) {

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop.cgColor, colorBottom.cgColor]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = aView.bounds
        
        aView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    static func setUnderlinedTextAttribute(text : String, button : UIButton) {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: NSMakeRange(0, attributeString.length))
        let range = NSRange(location: 0, length: text.characters.count)
        attributeString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white , range: range)
        button.setAttributedTitle(attributeString, for: .normal)
    }
    
    static func shakeView(_ shakeView: UIView) {
        let shake = CABasicAnimation(keyPath: "position")
        let xDelta = CGFloat(5)
        shake.duration = 0.15
        shake.repeatCount = 2
        shake.autoreverses = true
        
        let from_point = CGPoint(x: shakeView.center.x - xDelta, y: shakeView.center.y)
        let from_value = NSValue(cgPoint: from_point)
        
        let to_point = CGPoint(x: shakeView.center.x + xDelta, y: shakeView.center.y)
        let to_value = NSValue(cgPoint: to_point)
        
        shake.fromValue = from_value
        shake.toValue = to_value
        shake.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        shakeView.layer.add(shake, forKey: "position")
    }
    
    static func bounceView(viewOneIsIn : UIView, _ viewToBounce : UIView, completion: @escaping (_ success: Bool) -> ()) {
        viewToBounce.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 1,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: { [weak viewOneIsIn] in
                        viewToBounce.transform = .identity
            },
                       completion: { (success) in
                        completion(success)
        })
    }
    
    static func printDebugMessage(_ s : String) {
        print()
        print("-------------------------------------------------------")
        print(s)
        print("-------------------------------------------------------")
        print()
    }
    
    static func presentImagePicker(vc : UIViewController, vcDelegate : UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        let imagePickerController = UIImagePickerController()
        //imagePickerController.allowsEditing = true
        imagePickerController.delegate = vcDelegate
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        vc.present(imagePickerController, animated: true, completion: nil)
    }
    
    //Presents a loading screen view ontop of vcView, blocking user interaction
    static func presentLoadingScreen(vcView : UIView) -> LoadingScreenObject {
        vcView.isUserInteractionEnabled = false
        let loadingSquareScreenView = UIView(frame: vcView.frame)
        let backgroundColor = UIColor.black
        let (r,g,b,_) = backgroundColor.rgb()!
        loadingSquareScreenView.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 0.3)
        let loadingSquare : AASquaresLoading = AASquaresLoading(target: loadingSquareScreenView, size: 40)
        loadingSquare.isHidden = false
        loadingSquare.color = UIColor.white
        loadingSquare.backgroundColor = UIColor.clear
        loadingSquare.start()
        loadingSquareScreenView.isUserInteractionEnabled = false
        //loadingSquareScreenView.addSubview(loadingSquare)
        vcView.addSubview(loadingSquareScreenView)
        return LoadingScreenObject(loadingSquare: loadingSquare, view: loadingSquareScreenView)
    }
    
    //removes the loadingScreenObject from vcView, restoring user interaction
    static func removeLoadingScreen(loadingScreenObject : LoadingScreenObject, vcView : UIView) {
        loadingScreenObject.loadingSquare.stop()
        loadingScreenObject.view.isUserInteractionEnabled = true
        loadingScreenObject.view.isHidden = true
        loadingScreenObject.view.removeFromSuperview()
        vcView.isUserInteractionEnabled = true
    }
    
    class LoadingScreenObject {
        var loadingSquare : AASquaresLoading
        var view : UIView
        
        init(loadingSquare : AASquaresLoading, view : UIView)
        {
            self.loadingSquare = loadingSquare
            self.view = view
        }
    }
    
    static func animateToPlacesTabWithVenueIDandDate(venueID : String, date : Date) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.simpleTBC?.animateToTab(0, completion: { (vc) in
            if let navController = vc as? UINavigationController {
                if let vc = navController.topViewController as? PlacesTableViewController {
                    
                    vc.displayVenuePopupWithVenueIDForDay(venueID: venueID, date: date)
                }
                else {
                    Utilities.printDebugMessage("Error: could not convert VC")
                }
            }
            else {
                Utilities.printDebugMessage("Error: could not convert VC")
            }
            
        })
    }
    
    /*
     This function goes in the cocoapod SimpleTabBarController.swift:
     
     public func animateToTab(_ toIndex: Int, completion: @escaping (_ toVC : UIViewController) -> ()) {
     let tabViewControllers = viewControllers!
     let fromView = selectedViewController!.view
     let toView = tabViewControllers[toIndex].view
     let fromIndex = tabViewControllers.index(of: selectedViewController!)
     let toVC : UIViewController = viewControllers![toIndex]
     guard fromIndex != toIndex else {return}
     
     // Add the toView to the tab bar view
     fromView?.superview!.addSubview(toView!)
     
     // Position toView off screen (to the left/right of fromView)
     let screenWidth = UIScreen.main.bounds.size.width;
     let scrollRight = toIndex > fromIndex!;
     let offset = (scrollRight ? screenWidth : -screenWidth)
     toView?.center = CGPoint(x: (fromView?.center.x)! + offset, y: (toView?.center.y)!)
     
     // Disable interaction during animation
     view.isUserInteractionEnabled = false
     
     UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
     
     // Slide the views by -offset
     fromView?.center = CGPoint(x: (fromView?.center.x)! - offset, y: (fromView?.center.y)!);
     toView?.center   = CGPoint(x: (toView?.center.x)! - offset, y: (toView?.center.y)!);
     
     }, completion: { finished in
     
     // Remove the old view from the tabbar view.
     fromView?.removeFromSuperview()
     self.selectedIndex = toIndex
     self.view.isUserInteractionEnabled = true
     self.tabBar.selectedIndex = toIndex
     completion(toVC)
     })
     }
 
 */
    
    
    static func setPlurality(string : String, count : Int) -> String {
        if (count == 1) {
            return string
        }
        return string + "s"
    }
    
    static func setPluralityForPeople(count : Int) -> String {
        if (count == 1) {
            return "person"
        } else {
            return "people"
        }
    }
    
    static func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    static func generateRandomCongratulatoryPhrase() -> String {
        let random = Int(arc4random_uniform(UInt32(Constants.CONGRATULATORY_WORDS_LIST.count)))
        return Constants.CONGRATULATORY_WORDS_LIST[random]
    }
    
    static func showWalkthrough(vcDelegate : BWWalkthroughViewControllerDelegate, vc : UIViewController) {
        // Get view controllers and build the walkthrough
        let stb = UIStoryboard(name: "Walkthrough", bundle: nil)
        let walkthrough = stb.instantiateViewController(withIdentifier: "walk") as! BWWalkthroughViewController
        //let page_zero = stb.instantiateViewController(withIdentifier: "walk0")
        let page_one = stb.instantiateViewController(withIdentifier: "walk1")
        let page_two = stb.instantiateViewController(withIdentifier: "walk2")
        let page_three = stb.instantiateViewController(withIdentifier: "walk3")
        
        // Attach the pages to the master
        walkthrough.delegate = vcDelegate
        walkthrough.add(viewController:page_one)
        walkthrough.add(viewController:page_two)
        walkthrough.add(viewController:page_three)
        //walkthrough.add(viewController:page_zero)
        
        vc.present(walkthrough, animated: true, completion: nil)
        
    }
    
    static func sendPushNotification(title : String, text : String, toUserFBID : String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.users[toUserFBID] != nil) {
            if let toNotificationID = appDelegate.users[toUserFBID]!.NotificationInfo.notificationUserID {
                OneSignal.postNotification(["contents": ["en": text], "include_player_ids": [toNotificationID], "subtitle": ["en": title]])
            }
        }
    }
    
    static func sendPushNotification(title : String, toUserFBID : String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.users[toUserFBID] != nil) {
            if let toNotificationID = appDelegate.users[toUserFBID]!.NotificationInfo.notificationUserID {
                OneSignal.postNotification(["include_player_ids": [toNotificationID], "contents": ["en": title]])
            }
        }
    }
    
    static func sendPushNotificationToEntireFlock(title : String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var userNotificationIDs = [String]()
        for (friendFBID,_) in appDelegate.user!.Friends {
            if (appDelegate.users[friendFBID] != nil) {
                if let toNotificationID = appDelegate.users[friendFBID]!.NotificationInfo.notificationUserID {
                    userNotificationIDs.append(toNotificationID)
                }
            }
        }
        if (userNotificationIDs.count != 0) {
            OneSignal.postNotification(["include_player_ids": userNotificationIDs, "contents": ["en": title]])
        }
    }
    
    static func sendPushNotificationToPartOfFlock(title: String, toFriends : [String]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var userNotificationIDs = [String]()
        for friendFBID in toFriends {
            print(friendFBID)
            if (appDelegate.users[friendFBID] != nil) {
                if let toNotificationID = appDelegate.users[friendFBID]!.NotificationInfo.notificationUserID {
                    userNotificationIDs.append(toNotificationID)
                    print("Notification heading to: \(toNotificationID)")
                }
            }
        }
        if (userNotificationIDs.count != 0) {
            OneSignal.postNotification(["include_player_ids": userNotificationIDs, "contents": ["en": title]])
        }
    }
    
}

extension UIColor {
    
    func rgb() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = (fRed * 255.0)
            let iGreen = (fGreen * 255.0)
            let iBlue = (fBlue * 255.0)
            let iAlpha = (fAlpha * 255.0)
            
            return (red:iRed, green:iGreen, blue:iBlue, alpha:iAlpha)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}
