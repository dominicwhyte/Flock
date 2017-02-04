import UIKit
import Social
import MobileCoreServices
import AASquaresLoading

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
