//
//  PermissionUtilities.swift
//  Flock
//
//  Created by Dominic Whyte on 13/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import PermissionScope

class PermissionUtilities {
    static func getPermissionsIfNotYetSet(permissionScope : PermissionScope) {
        //checkContactsPermissions(permissionScope: permissionScope, checkIfDenied: false)
        checkLocationPermissions(permissionScope: permissionScope, checkIfDenied: false)
        checkNotificationsPermissions(permissionScope: permissionScope, checkIfDenied: false)
    }
    
    static func getPermissionsIfDenied(permissionScope : PermissionScope) {
        //checkContactsPermissions(permissionScope: permissionScope, checkIfDenied: true)
        checkLocationPermissions(permissionScope: permissionScope, checkIfDenied: true)
        checkNotificationsPermissions(permissionScope: permissionScope, checkIfDenied: true)
    }
    
    static func getPermissions(permissionScope : PermissionScope) {
        showPermissionsPopup(permissionScope: permissionScope)
    }

    
//    static func checkContactsPermissions(permissionScope : PermissionScope, checkIfDenied : Bool) {
//        switch PermissionScope().statusContacts() {
//        case .unknown:
//            showPermissionsPopup(permissionScope: permissionScope)
//        case .unauthorized, .disabled:
//            if (checkIfDenied) {
//                showPermissionsPopup(permissionScope: permissionScope)
//            }
//            return
//        case .authorized:
//            return
//        }
//    }
    
    static func setupPermissionScope(permissionScope : PermissionScope) {
        permissionScope.addPermission(NotificationsPermission(notificationCategories: nil),
                                  message: "Get notified when you're\r\nat a venue")
        permissionScope.addPermission(LocationAlwaysPermission(),
                                  message: "Let your Flock know\r\nwhen you're out")
    }
    
    static func checkNotificationsPermissions(permissionScope : PermissionScope, checkIfDenied : Bool) {
        switch PermissionScope().statusNotifications() {
        case .unknown:
            showPermissionsPopup(permissionScope: permissionScope)
        case .unauthorized, .disabled:
            if (checkIfDenied) {
                showPermissionsPopup(permissionScope: permissionScope)
            }
            return
        case .authorized:
            return
        }
    }
    
    static func checkLocationPermissions(permissionScope : PermissionScope, checkIfDenied : Bool) {
        switch PermissionScope().statusLocationAlways() {
        case .unknown:
            showPermissionsPopup(permissionScope: permissionScope)
        case .unauthorized, .disabled:
            if (checkIfDenied) {
                showPermissionsPopup(permissionScope: permissionScope)
            }
            return
        case .authorized:
            return
        }
    }
    //Show the popup for permissions
    static func showPermissionsPopup(permissionScope : PermissionScope) {
        permissionScope.show(
            { finished, results in
                print("got results \(results)")
        },
            cancelled: { results in
                print("thing was cancelled")
        }
        )
    }

}
