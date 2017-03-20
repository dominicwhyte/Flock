//
//  EventsViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 19/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class EventsViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    var events: [Event] = []
    var imageCache = [String : UIImage]()
    
    @IBOutlet var carousel: iCarousel!
    
    @IBOutlet weak var topCover: UIView!
    @IBOutlet weak var bottomCover: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        for _ in 0 ... 5 {
            let newDict = [EventFirebaseConstants.eventName : "Capmandu" as AnyObject, EventFirebaseConstants.eventDate : "2017-03-17" as AnyObject, EventFirebaseConstants.specialEvent : true as AnyObject, EventFirebaseConstants.venueID : "-KeKwZoP21jkaCs4LFN0" as AnyObject, EventFirebaseConstants.eventAttendeeFBIDs : ["10208026242633924" : "10208026242633924", "10206799811314250" : "10206799811314250", "10210419661620438" : "10210419661620438"] as AnyObject] as [String : AnyObject]
            let newEvent = Event(dict: newDict)
            events.append(newEvent)
        }
    }
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.setContentOffset(collectionView.contentOffset, animated:false) // Stops collection view if it was scrolling.
        
        super.viewDidLoad()
        carousel.type = .invertedWheel
        
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.backgroundView = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Utilities.applyVerticalGradient(aView: topCover, colorTop: FlockColors.FLOCK_BLUE, colorBottom: FlockColors.FLOCK_LIGHT_BLUE)
        //Utilities.applyVerticalGradient(aView: bottomCover, colorTop: FlockColors.FLOCK_LIGHT_BLUE, colorBottom: FlockColors.FLOCK_GOLD)
        bottomCover.backgroundColor = UIColor.white
        
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return events.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var eventView: EventView
        
        //reuse view if available, otherwise create a new view
        if let view = view as? EventView {
            eventView = view
            //get a reference to the label in the recycled view
            //label = itemView.viewWithTag(1) as! UILabel
        } else {
            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            eventView = EventView(frame: CGRect(x: 0, y: 0, width: 250, height: 250))
            eventView.setupEventView(event: events[index])
            
//            label = UILabel(frame: itemView.bounds)
//            label.backgroundColor = .clear
//            label.textAlignment = .center
//            label.font = label.font.withSize(50)
//            label.tag = 1
//            itemView.addSubview(label)
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel

        
        return eventView
    }
    

    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        }
        return value
    }
    
}

extension EventsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
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

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        Utilities.printDebugMessage("running")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FLOCK_SUGGESTION_COLLECTION_CELL", for: indexPath) as! FlockSuggestionCollectionViewCell
        cell.cellType = FlockSuggestionCollectionViewCell.CollectionViewCellType.messager
//        cell.delegate = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let suggestedUser = appDelegate.users["1590517560973218"]!
        let userImage = cell.viewWithTag(2) as! UIImageView
        let nameLabel = cell.viewWithTag(1) as! UILabel
        cell.userToFriendFBID = suggestedUser.FBID
        nameLabel.text = suggestedUser.Name
        userImage.makeViewCircle()
        self.retrieveImage(imageURL: suggestedUser.PictureURL, imageView: userImage)
        if let delegate = cell.delegate {
            if delegate.FBIDWasFlocked(fbid: suggestedUser.FBID) {
                cell.setPerformedUI()
            }
            else {
                cell.resetUINewCell()
            }
        }
        else {
            
            cell.resetUINewCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Collection view at row \(collectionView.tag) selected index path \(indexPath)")
    }
}


//    fileprivate var currentPage: Int = 0 {
//        didSet {
//            Utilities.printDebugMessage("changed")
//        }
//    }
//
//    fileprivate var pageSize: CGSize {
//        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
//        var pageSize = layout.itemSize
//        if layout.scrollDirection == .horizontal {
//            pageSize.width += layout.minimumLineSpacing
//        } else {
//            pageSize.height += layout.minimumLineSpacing
//        }
//        return pageSize
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setupLayout()
//
//
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.showsVerticalScrollIndicator = false
//
//        collectionView.delegate = self
//        collectionView.dataSource = self
//    }
//
//    fileprivate func setupLayout() {
//        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
//        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 30)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        return CGSize(width: 100, height: 20)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 5
//    }
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EVENT_CELL", for: indexPath) as! EventCollectionViewCell
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if (currentPage == indexPath.row) {
//            if let cell = collectionView.cellForItem(at: indexPath) as? EventCollectionViewCell {
//                Utilities.printDebugMessage("Cell selected")
//                cell.flip()
//            }
//
//        }
//    }
//
//    // MARK: - UIScrollViewDelegate
//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
//        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
//        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
//        currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
//    }
