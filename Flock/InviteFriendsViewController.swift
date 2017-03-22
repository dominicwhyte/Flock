import UIKit

import FBSDKCoreKit
import FBSDKShareKit

class InviteFriendsViewController: UIViewController {
    /**
     Sent to the delegate when the app invite completes without error.
     - Parameter appInviteDialog: The FBSDKAppInviteDialog that completed.
     - Parameter results: The results from the dialog.  This may be nil or empty.
     */
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/1911872325698779") as URL!
        content.appInvitePreviewImageURL = NSURL(string: "https://firebasestorage.googleapis.com/v0/b/flock-43b66.appspot.com/o/message_images%2F76C9E67E-1CAB-4454-9287-C02746850D91?alt=media&token=ef9cc51c-5db6-4983-b046-fa0ae8e0d4a3") as URL!
        
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
    }
    
    
    
}

extension InviteFriendsViewController: FBSDKAppInviteDialogDelegate{
    /**
     Sent to the delegate when the app invite encounters an error.
     - Parameter appInviteDialog: The FBSDKAppInviteDialog that completed.
     - Parameter error: The error.
     */
    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        Utilities.printDebugMessage("LETS GO")
    }

    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
        let resultObject = NSDictionary(dictionary: results)
        
        if let didCancel = resultObject.value(forKey: "completionGesture")
        {
            if (didCancel as AnyObject).caseInsensitiveCompare("Cancel") == ComparisonResult.orderedSame
            {
                print("User Canceled invitation dialog")
            }
        }
    }
}
