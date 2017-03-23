
//
//  SwiftAddressBookSource.swift
//  Pods
//
//  Created by Socialbit - Tassilo Karge on 09.03.15.
//
//

import Foundation
import AddressBook

//MARK: Wrapper for ABAddressBookRecord of type ABSource

open class SwiftAddressBookSource : SwiftAddressBookRecord {

	open var sourceType : SwiftAddressBookSourceType {
		get {
			return SwiftAddressBookSourceType(abSourceType: internalSourceType)
		}
	}

	open var searchable : Bool {
		get {
			return (kABSourceTypeSearchableMask & internalSourceType) != 0
		}
	}

	fileprivate var internalSourceType : Int32 {
		get {
			let sourceType = ABRecordCopyValue(internalRecord, kABSourceTypeProperty)?.takeRetainedValue() as! NSNumber
			return sourceType.int32Value
		}
	}

	open var sourceName : String? {
		get {
			return ABRecordCopyValue(internalRecord, kABSourceNameProperty)?.takeRetainedValue() as? String
		}
	}
}
