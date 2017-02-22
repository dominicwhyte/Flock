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

class ChatViewController: JSQMessagesViewController {
    
    //channelRef into the correct channel ID
    //Set during segue
    var channelRef: FIRDatabaseReference?
    var friendUser: User?
    var friendImage: UIImage?
    var userImage: UIImage?
    
    
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //typing
    private lazy var userIsTypingRef: FIRDatabaseReference = self.channelRef!.child("typingIndicator").child(self.senderId)
    private lazy var usersTypingQuery: FIRDatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    private var localTyping = false
    
    var messages = [JSQMessage]()
    var hasBeenReadArray = [Bool]()
    var sendDates = [String]()
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
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
//        if let refHandle = updatedMessageRefHandle {
//            messageRef.removeObserver(withHandle: refHandle)
//        }
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
        
        if(sendDate != "") {
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
        let itemRef = messageRef.childByAutoId() // 1
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
                self.finishReceivingMessage()
                
            } else {
                print("Error! Could not decode message data")
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

}
