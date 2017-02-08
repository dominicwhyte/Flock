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

struct FlockColors {
    static let FLOCK_BLUE = UIColor(red: 76/255, green: 181/255, blue: 245/255, alpha: 1.0)
    static let FLOCK_GRAY = UIColor(red: 183/255, green: 184/255, blue: 182/255, alpha: 1.0)
    static let FLOCK_LIGHT_BLUE = UIColor(red: 129/255, green: 202/255, blue: 247/255, alpha: 1.0)
}

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
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupSimpleTab()
        
    }
    
    
    
    func setupSimpleTab() {
        
        //# Get Handle of Tab Bar Control
        /* In storyboard, ensure :
         - Tab Bar Controller is set as SimpleTabBarController
         - Tab Bar is set as SimpleTabBar
         - Tab Bar Item is set as SimpleTabBarItem
         */
        let simpleTBC : SimpleTabBarController = self
        
        //# Set the View Transition
//        simpleTBC.viewTransition = PopViewTransition()
        simpleTBC.viewTransition = CrossFadeViewTransition()
        
        //# Set Tab Bar Style ( tab bar , tab item animation style etc )
        let style:SimpleTabBarStyle = PopTabBarStyle(tabBar: simpleTBC.tabBar)
        //var style:SimpleTabBarStyle = ElegantTabBarStyle(tabBar: simpleTBC!.tabBar)
        
        //# Optional - Set Tab Title attributes for selected and unselected (normal) states.
        // Or use the App tint color to set the states
        style.setTitleTextAttributes([NSFontAttributeName as NSObject : UIFont.systemFont(ofSize: 14),  NSForegroundColorAttributeName as NSObject: UIColor.lightGray], forState: .normal)
        style.setTitleTextAttributes([NSFontAttributeName as NSObject : UIFont.systemFont(ofSize: 14),NSForegroundColorAttributeName as NSObject: FlockColors.FLOCK_BLUE], forState: .selected)
        
        //# Optional - Set Tab Icon colors for selected and unselected (normal) states.
        // Or use the App tint color to set the states
        style.setIconColor(UIColor.lightGray, forState: UIControlState.normal)
        style.setIconColor(colorWithHexString("4CB5F5"), forState: UIControlState.selected)
        
        //# Let the tab bar control know of the style
        // Note: All style settings must be done prior to this.
        simpleTBC.tabBarStyle = style
    }
    
    //# Handy function to return UIColors from Hex Strings
    func colorWithHexString (_ hexStr:String) -> UIColor {
        
        let hex = hexStr.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        
    }
    
    ///View Transitioning Object
    open var viewTransition:UIViewControllerAnimatedTransitioning?

    ///Tab Bar Style ( with animation control for tab switching )
    open var tabBarStyle:SimpleTabBarStyle? {
        didSet {
            self.tabBarStyle?.refresh()
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //Initial setup
        tabBar.selectedIndex = self.selectedIndex
        tabBar.transitionObject = self.viewTransition! ?? CrossFadeViewTransition()
        tabBar.tabBarStyle = self.tabBarStyle! ?? ElegantTabBarStyle(tabBar: tabBar)
        tabBar.tabBarCtrl = self
        self.delegate = tabBar

        //Let the style object know when things are loaded
        self.tabBarStyle?.tabBarCtrlLoaded(self, tabBar: tabBar, selectedIndex: tabBar.selectedIndex)

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
            completion(toVC)
        })
    }
}
