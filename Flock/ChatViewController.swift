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
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    private var channelRefHandle: FIRDatabaseHandle?
    private var channel: Channel?
    
    private func createChannel(channelName : String) {
        let newChannelRef = channelRef.childByAutoId() // 2
        let channelItem = [ // 3
            "name": channelName
        ]
        newChannelRef.setValue(channelItem) // 4
    }
    
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }

    // MARK: Firebase related methods
    private func observeChannels() {
        // Use the observe method to listen for new
        // channels being written to the Firebase DB
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in // 1
            let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
            let id = snapshot.key
            if let name = channelData["name"] as! String!, name.characters.count > 0 { // 3
                self.channel = Channel(id: id, name: name)
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeChannels()
    }
    

}
