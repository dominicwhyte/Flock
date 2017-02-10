import UIKit
import Social
import MobileCoreServices
import AASquaresLoading

struct FlockColors {
    static let FLOCK_BLUE = UIColor(red: 76/255, green: 181/255, blue: 245/255, alpha: 1.0)
    static let FLOCK_GRAY = UIColor(red: 183/255, green: 184/255, blue: 182/255, alpha: 1.0)
    static let FLOCK_LIGHT_BLUE = UIColor(red: 129/255, green: 202/255, blue: 247/255, alpha: 1.0)
}

class Utilities {
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
