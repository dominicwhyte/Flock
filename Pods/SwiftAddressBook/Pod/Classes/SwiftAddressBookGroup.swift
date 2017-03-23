//
//  SwiftAddressBookGroup.swift
//  Pods
//
//  Created by Socialbit - Tassilo Karge on 09.03.15.
//
//

import Foundation
import AddressBook

//MARK: Wrapper for ABAddressBookRecord of type ABGroup

open class SwiftAddressBookGroup : SwiftAddressBookRecord {

	open var name : String? {
		get {
			return ABRecordCopyValue(internalRecord, kABGroupNameProperty)?.takeRetainedValue() as? String
		}
		set {
			ABRecordSetValue(internalRecord, kABGroupNameProperty, newValue as CFTypeRef!, nil)
		}
	}

	open class func create() -> SwiftAddressBookGroup {
		return SwiftAddressBookGroup(record: ABGroupCreate().takeRetainedValue())
	}

	open class func createInSource(_ source : SwiftAddressBookSource) -> SwiftAddressBookGroup {
		return SwiftAddressBookGroup(record: ABGroupCreateInSource(source.internalRecord).takeRetainedValue())
	}

	open var allMembers : [SwiftAddressBookPerson]? {
		get {
			return convertRecordsToPersons(ABGroupCopyArrayOfAllMembers(internalRecord)?.takeRetainedValue())
		}
	}

	open func allMembersWithSortOrdering(_ ordering : SwiftAddressBookOrdering) -> [SwiftAddressBookPerson]? {
		return convertRecordsToPersons(ABGroupCopyArrayOfAllMembersWithSortOrdering(internalRecord, ordering.abPersonSortOrderingValue).takeRetainedValue())
	}

	open func addMember(_ person : SwiftAddressBookPerson) -> CFError? {
		return errorIfNoSuccess { ABGroupAddMember(self.internalRecord, person.internalRecord, $0) }
	}

	open func removeMember(_ person : SwiftAddressBookPerson) -> CFError? {
		return errorIfNoSuccess { ABGroupRemoveMember(self.internalRecord, person.internalRecord, $0) }
	}

	open var source : SwiftAddressBookSource {
		get {
			return SwiftAddressBookSource(record: ABGroupCopySource(internalRecord).takeRetainedValue())
		}
	}
}
