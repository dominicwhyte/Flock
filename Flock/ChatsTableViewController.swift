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
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.tableView.separatorColor = FlockColors.FLOCK_BLUE
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.user = appDelegate.user!
        for(FBID, channelID) in self.user!.ChannelIDs {
            let friend = appDelegate.users[FBID]!
            let conversation = Conversation(channelID: channelID, participant: friend, imageURL : friend.PictureURL, lastMessage: nil )
            
            self.conversations.append(conversation)
            self.conversations.sort(by: { (conversation1, conversation2) -> Bool in
                
                var unreadCount1 = 0
                var unreadCount2 = 0
                if appDelegate.unreadMessageCount[conversation1.channelID] != nil {
                    unreadCount1 = appDelegate.unreadMessageCount[conversation1.channelID]!
                }
                if appDelegate.unreadMessageCount[conversation2.channelID] != nil {
                    unreadCount2 = appDelegate.unreadMessageCount[conversation2.channelID]!
                }
                if(unreadCount1 > 0 && unreadCount2 == 0) {
                    return true
                } else if (unreadCount1 == 0 && unreadCount2 > 0) {
                    return false
                } else {
                    return conversation1.participant.Name < conversation2.participant.Name
                }
            })
            
        }
        
        // Remove appDelegate observer as soon as we start observing:
        
        var totalUnread = 0
        for (_, count) in appDelegate.unreadMessageCount {
            totalUnread += count
        }
        //        if let stb = appDelegate.simpleTBC {
        //            if totalUnread > 0 {
        //                stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
        //            } else {
        //                stb.removeAllBadges()
        //            }
        //        }
        
        self.retrieveUserImageWithoutSetting(imageURL: self.user!.PictureURL, venueID: nil)
        
        //Search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY
        
        searchController.searchBar.placeholder = "Search                                                                                     "
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func resetChats() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for(FBID, channelID) in self.user!.ChannelIDs {
            let friend = appDelegate.users[FBID]!
            let conversation = Conversation(channelID: channelID, participant: friend, imageURL : friend.PictureURL, lastMessage: nil )
            
            self.conversations.append(conversation)
            self.conversations.sort(by: { (conversation1, conversation2) -> Bool in
                
                var unreadCount1 = 0
                var unreadCount2 = 0
                if appDelegate.unreadMessageCount[conversation1.channelID] != nil {
                    unreadCount1 = appDelegate.unreadMessageCount[conversation1.channelID]!
                }
                if appDelegate.unreadMessageCount[conversation2.channelID] != nil {
                    unreadCount2 = appDelegate.unreadMessageCount[conversation2.channelID]!
                }
                if(unreadCount1 > 0 && unreadCount2 == 0) {
                    return true
                } else if (unreadCount1 == 0 && unreadCount2 > 0) {
                    return false
                } else {
                    return conversation1.participant.Name < conversation2.participant.Name
                }
            })
            
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        self.filteredConversations = (conversations.filter({( convo : Conversation) -> Bool in
                return convo.participant.Name.lowercased().contains(searchText.lowercased())
            
        }))
        
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.user = appDelegate.user!
        var newConversations = [Conversation]()
        
        for(FBID, channelID) in self.user!.ChannelIDs {
            let friend = appDelegate.users[FBID]!
            let conversation = Conversation(channelID: channelID, participant: friend, imageURL : friend.PictureURL, lastMessage: nil )
            
            newConversations.append(conversation)
            newConversations.sort(by: { (conversation1, conversation2) -> Bool in
                conversation1.participant.Name < conversation2.participant.Name
            })
            
        }
        self.conversations = newConversations
        
        self.tableView.reloadData()
        self.tableView.setNeedsDisplay()
        self.tableView.setNeedsLayout()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, venueID: String?, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
                DispatchQueue.main.async {
                    self.imageCache[imageURL] = image
                    imageView.image = image
                }
            }
        }
        
    }
    
    func retrieveUserImageWithoutSetting(imageURL : String, venueID: String?) {
        FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
            DispatchQueue.main.async {
                self.imageCache[imageURL] = image
            }
        }
        
    }
    
    var conversations = [Conversation]()
    var filteredConversations = [Conversation]()
    var user : User?
    var imageCache = [String : UIImage]()
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != "" {
            return self.filteredConversations.count
        }
        return conversations.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ChatTableViewCell
        //cell.selectionStyle = .none
        //Setup Cell
        let conversation : Conversation
        if searchController.isActive && searchController.searchBar.text != "" {
            conversation = self.filteredConversations[indexPath.row]
        }
        else {
            conversation = self.conversations[indexPath.row]
        }
        var labelsHaveBeenUpdated = false
        
        //Lines go all the way
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        cell.chatTitle.text = conversation.participant.Name
        cell.chatSubtitle.text = ""
        cell.unreadMessagesLabel.isHidden = true
        //var unreadCount = 0
        if(conversation.lastMessage == nil) {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            
            let channelRef = FIRDatabase.database().reference().child("channels").child(conversation.channelID)
            
            let messageRef = channelRef.child("messages")
            // 1.
            let messageQuery = messageRef.queryLimited(toLast:5)
            
            let _ = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
                // 3
                let messageData = snapshot.value as! Dictionary<String, String>
                if let id = messageData["senderId"] as String!, let _ = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                    // 4
                    //self.addMessage(withId: id, name: name, text: text)
                    conversation.lastMessage = text
                    conversation.lastSenderId = id
                    
                    if (messageData["hasBeenRead"] != nil){
                        let hasBeenRead = messageData["hasBeenRead"]!
                        if((hasBeenRead == "false") && (id != self.user!.FBID)) {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            if let count = appDelegate.unreadMessageCount[conversation.channelID] {
                                //appDelegate.unreadMessageCount[conversation.channelID]! += 1
                            } else {
                                //appDelegate.unreadMessageCount[conversation.channelID] = 1
                            }
                            labelsHaveBeenUpdated = false
                        }
                    }
                } else {
                    print("Error! Could not decode message data")
                }
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                var unreadCount = 0
                if appDelegate.unreadMessageCount[conversation.channelID] != nil {
                    unreadCount = appDelegate.unreadMessageCount[conversation.channelID]!
                }
                
                var totalUnread = 0
                for count in Array(appDelegate.unreadMessageCount.values) {
                    totalUnread += count
                }
                
                //                if let stb = appDelegate.simpleTBC {
                //                    if totalUnread > 0 {
                //                        stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                //                    } else {
                //                        stb.removeAllBadges()
                //                    }
                //                }
                if(unreadCount > 0 && !labelsHaveBeenUpdated) {
                    // Unread messages
                    if(unreadCount > 0 && unreadCount <= 5) {
                        // Cell label
                        cell.unreadMessagesLabel.isHidden = false
                        cell.unreadMessagesLabel.text = "+"//"\(unreadCount)"
                        cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                        cell.unreadMessagesLabel.clipsToBounds = true
                        labelsHaveBeenUpdated = true
                        
                    } else if(unreadCount > 5) {
                        cell.unreadMessagesLabel.isHidden = false
                        cell.unreadMessagesLabel.text = "+"//"5+"
                        cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                        cell.unreadMessagesLabel.clipsToBounds = true
                        labelsHaveBeenUpdated = true
                    }
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
                    
                }
            })
            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
        } else {
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
        }
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var unreadCount = 0
        if appDelegate.unreadMessageCount[conversation.channelID] != nil {
            unreadCount = appDelegate.unreadMessageCount[conversation.channelID]!
        }
        
        var totalUnread = 0
        for count in Array(appDelegate.unreadMessageCount.values) {
            totalUnread += count
        }
        
        //        if let stb = appDelegate.simpleTBC {
        //            if totalUnread > 0 {
        //                stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
        //            } else {
        //                stb.removeAllBadges()
        //            }
        //        }
        if(unreadCount > 0 && !labelsHaveBeenUpdated) {
            // Unread messages
            if(unreadCount > 0 && unreadCount <= 5) {
                // Cell label
                cell.unreadMessagesLabel.isHidden = false
                cell.unreadMessagesLabel.text = "+"//"\(unreadCount)"
                cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                cell.unreadMessagesLabel.clipsToBounds = true
                
            } else if(unreadCount > 5) {
                cell.unreadMessagesLabel.isHidden = false
                cell.unreadMessagesLabel.text = "+"//"5+"
                cell.unreadMessagesLabel.layer.cornerRadius = cell.unreadMessagesLabel.frame.size.width/2
                cell.unreadMessagesLabel.clipsToBounds = true
            }
        }
        
        self.retrieveImage(imageURL: conversation.imageURL!, venueID: nil, imageView: cell.chatImage)
        cell.chatImage.makeViewCircle()
        //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
        //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
        //cell.subtitleLabel.text = "\(venue.CurrentAttendees.count) live   \(venue.PlannedAttendees.count) planned"
        
        
        return cell
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation : Conversation
        if searchController.isActive && searchController.searchBar.text != "" {
            conversation = filteredConversations[indexPath.row]
        }
        else {
            conversation = conversations[indexPath.row]
        }
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
                    chatViewController.channelID = channelID
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

extension UITabBarController {
    
    func setBadges(badgeValues: [Int]) {
        
        for view in self.tabBar.subviews {
            if view is CustomTabBadge {
                view.removeFromSuperview()
            }
        }
        
        for index in 0...badgeValues.count-1 {
            if badgeValues[index] != 0 {
                addBadge(index: index, value: badgeValues[index], color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
            }
        }
    }
    
    func addBadge(index: Int, value: Int, color: UIColor, font: UIFont) {
        let badgeView = CustomTabBadge()
        
        badgeView.clipsToBounds = true
        badgeView.textColor = UIColor.white
        badgeView.textAlignment = .center
        badgeView.font = font
        if(value == -1) {
            badgeView.text = "+"//"5+"
        } else {
            badgeView.text = "+"//String(value)
        }
        badgeView.backgroundColor = color
        badgeView.tag = index
        if(index == 7) {
            tabBar.addSubview(badgeView)
            self.positionBadges()
        }
    }
    
    func removeAllBadges() {
        for view in self.tabBar.subviews {
            if view is CustomTabBadge {
                view.removeFromSuperview()
            }
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tabBar.setNeedsLayout()
        self.tabBar.layoutIfNeeded()
        self.positionBadges()
    }
    
    // Positioning
    func positionBadges() {
        
        var tabbarButtons = self.tabBar.subviews.filter { (view: UIView) -> Bool in
            return view.isUserInteractionEnabled // only UITabBarButton are userInteractionEnabled
        }
        
        tabbarButtons = tabbarButtons.sorted(by: { $0.frame.origin.x < $1.frame.origin.x })
        
        for view in self.tabBar.subviews {
            if view is CustomTabBadge {
                let badgeView = view as! CustomTabBadge
                self.positionBadge(badgeView: badgeView, items:tabbarButtons, index: badgeView.tag)
            }
        }
    }
    
    func positionBadge(badgeView: UIView, items: [UIView], index: Int) {
        let itemView = items[index]
        let center = itemView.center
        
        // Get whether or not we're on the ChatVC
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stb = appDelegate.simpleTBC!
        let selectedIndex = stb.selectedIndex
        var xOffset: CGFloat = 20
        var yOffset: CGFloat = -15
        // ChatTabIndex
        if(selectedIndex == 2) {
            xOffset = 20
            yOffset = -37
        }
        
        
        badgeView.frame.size = CGSize(width: 17, height: 17)
        badgeView.center = CGPoint(x: center.x + xOffset,y: center.y + yOffset)
        badgeView.layer.cornerRadius = badgeView.bounds.width/2
        tabBar.bringSubview(toFront: badgeView)
    }
    
    
}

extension ChatsTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension ChatsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

class CustomTabBadge: UILabel {}


