//
//  SimpleTabBarController.swift
//  XStreet
//
//  Created by azfx on 07/20/2015.
//  Copyright (c) 2015 azfx. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE..

import UIKit

open class SimpleTabBarController: UITabBarController {

    var _tabBar:SimpleTabBar?

    ///Tab Bar Component
    override open var tabBar:SimpleTabBar {
        get {
            return super.tabBar as! SimpleTabBar
        }
        set {

        }
    }

    ///View Transitioning Object
    open var viewTransition:UIViewControllerAnimatedTransitioning? {
        didSet {
            tabBar.transitionObject = self.viewTransition
        }
    }

    ///Tab Bar Style ( with animation control for tab switching )
    open var tabBarStyle:SimpleTabBarStyle? {
        didSet {
            self.tabBarStyle?.refresh()
        }
    }
    
    /**
    Set or Get Selected Index
    */
    override open var selectedIndex:Int {
        get {
            return super.selectedIndex
        }
        set {
            super.selectedIndex = newValue
            self.tabBar.selectedIndex = newValue
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Initial setup
        tabBar.selectedIndex = self.selectedIndex
        tabBar.transitionObject = self.viewTransition ?? CrossFadeViewTransition()
        tabBar.tabBarStyle = self.tabBarStyle ?? SimpleTabBarStyle(tabBar: tabBar)
        tabBar.tabBarCtrl = self
        self.delegate = tabBar

        //Let the style object know when things are loaded
        self.tabBarStyle?.tabBarCtrlLoaded(tabBarCtrl: self, tabBar: tabBar, selectedIndex: tabBar.selectedIndex)

    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
}
