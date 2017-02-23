//
//  ChatsTableViewController.swift
//
//
//  Created by Grant Rheingold on 2/19/17.
//
//

import UIKit
import JSQMessagesViewController
import Firebase

class ChatsTableViewController: UITableViewController {
    
    
    fileprivate let reuseIdentifier = "CHAT"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = FlockColors.FLOCK_BLUE
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.user = appDelegate.user!
        Utilities.printDebugMessage("1")
        for(FBID, channelID) in self.user!.ChannelIDs {
            let friend = appDelegate.users[FBID]!
            let conversation = Conversation(channelID: channelID, participant: friend, imageURL : friend.PictureURL, lastMessage: nil )
            
            self.conversations.append(conversation)
            self.conversations.sort(by: { (conversation1, conversation2) -> Bool in
                conversation1.participant.Name < conversation2.participant.Name
            })
            Utilities.printDebugMessage("getting conversation for \(friend.Name)")
        }
        self.retrieveUserImageWithoutSetting(imageURL: self.user!.PictureURL)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.printDebugMessage("HERE")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL) { (image) in
                DispatchQueue.main.async {
                    self.imageCache[imageURL] = image
                    imageView.image = image
                }
            }
        }
        
    }
    
    func retrieveUserImageWithoutSetting(imageURL : String) {
        FirebaseClient.getImageFromURL(imageURL) { (image) in
            DispatchQueue.main.async {
                self.imageCache[imageURL] = image
            }
        }

    }
    
    var conversations = [Conversation]()
    var user : User?
    var imageCache = [String : UIImage]()
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return conversations.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ChatTableViewCell
        //cell.selectionStyle = .none
        //Setup Cell
        let conversation : Conversation = self.conversations[indexPath.row]
        
        
        cell.chatTitle.text = conversation.participant.Name
        cell.chatSubtitle.text = ""
        cell.unreadMessagesLabel.isHidden = true
        var unreadCount = 0
        if(conversation.lastMessage == nil) {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            
            let channelRef = FIRDatabase.database().reference().child("channels").child(conversation.channelID)
            
            let messageRef = channelRef.child("messages")
            // 1.
            let messageQuery = messageRef.queryLimited(toLast:10)
            let _ = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
                // 3
                let messageData = snapshot.value as! Dictionary<String, String>
                if let id = messageData["senderId"] as String!, let _ = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                    // 4
                    //self.addMessage(withId: id, name: name, text: text)
                    conversation.lastMessage = text
                    conversation.lastSenderId = id
                    
                    if let hasBeenRead = (messageData["hasBeenRead"] != nil) as Bool!{
                        if(!hasBeenRead && (id != self.user!.FBID)) {
                            unreadCount += 1
                        }
                        Utilities.printDebugMessage(messageData["hasBeenRead"]! as String)
                    }
                    Utilities.printDebugMessage("\(unreadCount)")
                    
                } else {
                    print("Error! Could not decode message data")
                }
                
                DispatchQueue.main.async {
                    if(conversation.lastMessage != nil) {
                        if(conversation.lastSenderId == self.user!.FBID) {
                            cell.chatSubtitle.text = "Me: \(conversation.lastMessage!)"
                        } else {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            let friendName = appDelegate.users[conversation.lastSenderId!]!.Name
                            cell.chatSubtitle.text = "\(friendName): \(conversation.lastMessage!)"
                        }
                    } else {
                        cell.chatSubtitle.text = ""
                    }
                    
                    // Unread messages
                    if(unreadCount > 0 && unreadCount < 5) {
                        cell.unreadMessagesLabel.isHidden = false
                        cell.unreadMessagesLabel.text = "\(unreadCount)"
                        cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                        cell.unreadMessagesLabel.clipsToBounds = true
                    } else if(unreadCount > 5) {
                        cell.unreadMessagesLabel.isHidden = false
                        cell.unreadMessagesLabel.text = "5+"
                        cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                        cell.unreadMessagesLabel.clipsToBounds = true
                    }
                }
            })
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
        } else {
            cell.chatSubtitle.text = conversation.lastMessage
        }
        

        self.retrieveImage(imageURL: conversation.imageURL!, imageView: cell.chatImage)
        cell.chatImage.makeViewCircle()
        //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
        //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
        //cell.subtitleLabel.text = "\(venue.CurrentAttendees.count) live   \(venue.PlannedAttendees.count) planned"
        Utilities.printDebugMessage("Setting up cell")
        return cell
        
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        let FBID = conversation.participant.FBID
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let user = appDelegate.user, let friendUser = appDelegate.users[FBID] {
            if let channelID = user.ChannelIDs[FBID] {
                performSegue(withIdentifier: "CHAT_IDENTIFIER", sender: (channelID, friendUser))
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let chatViewController = navController.topViewController as? ChatViewController {
                if let (channelID, friendUser) = sender as? (String, User) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if let friendImage = imageCache[friendUser.PictureURL], let userImage = imageCache[appDelegate.user!.PictureURL] {
                        chatViewController.userImage = userImage
                        chatViewController.friendImage = friendImage
                    }
                    chatViewController.channelRef = FIRDatabase.database().reference().child("channels").child(channelID)
                    chatViewController.friendUser = friendUser
                }
            }
        }
    }
    
    func makeViewCircle(imageView : UIView) {
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
}

class Conversation {
    let channelID: String
    let participant: User
    let imageURL : String?
    var channelRef: FIRDatabaseReference?
    var lastMessage : String?
    var lastSenderId : String?
    
    init(channelID: String, participant: User, imageURL : String?, lastMessage : String?) {
        self.channelID = channelID
        self.participant = participant
        self.imageURL = imageURL
        self.channelRef = FIRDatabase.database().reference().child("channels").child(channelID)
        self.lastMessage = lastMessage
    }
}

