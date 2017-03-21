//
//  ChatViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 16/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import Photos
import SCLAlertView

class ChatViewController: JSQMessagesViewController {
    
    //channelRef into the correct channel ID
    //Set during segue
    var channelRef: FIRDatabaseReference?
    var friendUser: User?
    var friendImage: UIImage?
    var userImage: UIImage?
    var channelID: String?
    
    
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://flock-43b66.appspot.com")
    private let imageURLNotSetKey = "NOTSET"
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //typing
    private lazy var userIsTypingRef: FIRDatabaseReference = self.channelRef!.child("typingIndicator").child(self.senderId)
    private lazy var usersTypingQuery: FIRDatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    private var localTyping = false
    
    var messages = [JSQMessage]()
    var hasBeenReadArray = [Bool]()
    var sendDates = [String]()
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add title
        if let friendUser = self.friendUser {
            self.navigationItem.title = friendUser.Name
            
            let attrs = [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 18)!
            ]
            self.navigationController?.navigationBar.titleTextAttributes = attrs
        }
    }

    
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            
            // You're the only typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    var isTyping: Bool {
        get {
            //return localTyping
            return false
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "hasBeenRead" : "false",
            "sendDate" : DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: "MMM d h:mma")

            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        _ = SCLAlertView(appearance: SCLAlertView.SCLAppearance.init()).showNotice("Coming soon", subTitle: "Image uploads will be available in Version 2.0")
        /*
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        } else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        present(picker, animated: true, completion:nil)*/
        
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        //isTyping = textView.text != ""
        // the above is overwritten until we can figure out what's going on
        isTyping = false
    }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: FlockColors.FLOCK_BLUE)
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) { 
            //do nothing
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.senderId = appDelegate.user?.FBID
        self.senderDisplayName = appDelegate.user?.Name
        
        // No avatars
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        
        // animates the receiving of a new message on the view
        finishReceivingMessage()
        
        // Observe messages
        observeMessages()
        
        // Update appDelegate's messages handler to know how many unread there are
        if let channelID = self.channelID {
            appDelegate.unreadMessageCount[channelID] = 0
        }
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        
        if let userImage = userImage, let friendImage = friendImage {
            if message.senderId == senderId {
                return JSQMessagesAvatarImage(avatarImage: userImage, highlightedImage: userImage, placeholderImage: userImage)
            }
            else {
                //NOT SCALABLE FOR GROUPS
                return JSQMessagesAvatarImage(avatarImage: friendImage, highlightedImage: friendImage, placeholderImage: friendImage)
            }
        }
        else {
            let image = UIImage(named: "appLogo")
            return JSQMessagesAvatarImage(avatarImage: image, highlightedImage: image, placeholderImage: image)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        let hasBeenRead = hasBeenReadArray[indexPath.item]
        if(self.messages.count - indexPath.item < 5) {
            if(hasBeenRead) {
                cell.cellBottomLabel.text = "Read"
            } else {
                cell.cellBottomLabel.text = "Unread"
            }
        }
        let sendDate = sendDates[indexPath.item]
        
        if(sendDate != "" && (indexPath.item % 2 == 0)) {
            cell.cellTopLabel.text = sendDate
        }

        cell.messageBubbleTopLabel.text = message.senderDisplayName
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let itemRef = messageRef.childByAutoId() // 1
        if let friendUser = self.friendUser, let senderUser = appDelegate.user {
            Utilities.sendPushNotification(title: "Message from \(senderUser.Name)", text: text, toUserFBID: friendUser.FBID)
        }
        else {
            Utilities.printDebugMessage("Error: no friend to send notification to")
        }
        
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            "hasBeenRead" : "false",
            "sendDate" : DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: "MMM d h:mma")
            ]
        
        itemRef.setValue(messageItem) // 3
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
    }
    
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        // 1.
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                // 4
                
                var hasBeenRead = false
                if (messageData["hasBeenRead"] != nil) {
                    if(messageData["hasBeenRead"]! as String == "false") {
                        hasBeenRead = false
                    } else {
                        hasBeenRead = true
                    }
                }
                
                var sendDate : String
                if (messageData["sendDate"] != nil) {
                    sendDate = messageData["sendDate"] as String!
                } else {
                    sendDate = ""
                }
                
                // 5
                
                // 6 Update FireBase
                if(id != self.senderId) {
                    hasBeenRead = true
                }
                
                self.addMessage(withId: id, name: name, text: text, hasBeenRead: hasBeenRead, sendDate : sendDate)
                if(id != self.senderId) {
                    let updates = [ // 2
                        "senderId": id,
                        "senderName": name,
                        "text": text,
                        "hasBeenRead" : "true",
                        "sendDate" : sendDate
                        ]
                    self.messageRef.child(snapshot.key).updateChildValues(updates)
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                //if let channelID = self.channelID {
                //    appDelegate.unreadMessageCount[channelID] = 0
                //}
                self.finishReceivingMessage()
            }
            else if let id = messageData["senderId"] as String!,
                let photoURL = messageData["photoURL"] as String! { // 1
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    
                    var hasBeenRead = false
                    if (messageData["hasBeenRead"] != nil) {
                        if(messageData["hasBeenRead"]! as String == "false") {
                            hasBeenRead = false
                        } else {
                            hasBeenRead = true
                        }
                    }
                    var sendDate : String
                    if (messageData["sendDate"] != nil) {
                        sendDate = messageData["sendDate"] as String!
                    } else {
                        sendDate = ""
                    }
                    
                    self.addPhotoMessage(withId: id, key: snapshot.key, hasBeenRead: hasBeenRead, sendDate: sendDate, mediaItem: mediaItem)
                    // 4
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
            else {
                print("Error! Could not decode message data")
            }
        })
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData["photoURL"] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
    
    private func addMessage(withId id: String, name: String, text: String, hasBeenRead: Bool, sendDate: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
            hasBeenReadArray.append(hasBeenRead)
            sendDates.append(sendDate)
        }
    }
    
    private func addPhotoMessage(withId id: String, key: String, hasBeenRead: Bool, sendDate: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            hasBeenReadArray.append(hasBeenRead)
            sendDates.append(sendDate)
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        
        // 2
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage.init(data: data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }

}

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // 1
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // 2
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            // 3
            if let key = sendPhotoMessage() {
                // 4
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    
                    // 5
                    let path = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    // 6
                    self.storageRef.child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // 7
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // Handle picking a Photo from the Camera - TODO
            // 1
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2
            if let key = sendPhotoMessage() {
                // 3
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                // 4
                let imagePath = FIRAuth.auth()!.currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                // 5
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6
                storageRef.child(imagePath).put(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
