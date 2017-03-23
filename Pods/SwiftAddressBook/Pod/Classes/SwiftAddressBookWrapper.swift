//SwiftAddressBook - A strong-typed Swift Wrapper for ABAddressBook
//Copyright (C) 2014  Socialbit GmbH
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import UIKit
import AddressBook

@available(iOS, deprecated: 9.0)

//MARK: global address book variable (automatically lazy)

public let swiftAddressBook : SwiftAddressBook! = SwiftAddressBook()
public var accessError : CFError?

//MARK: Address Book

open class SwiftAddressBook {
    
    open var internalAddressBook : ABAddressBook!
    
    //fileprivate lazy var addressBookObserver = SwiftAddressBookObserver()
    
    public init?() {
        var err : Unmanaged<CFError>? = nil
        let abUnmanaged : Unmanaged<ABAddressBook>? = ABAddressBookCreateWithOptions(nil, &err)
        
        //assign error or internalAddressBook, according to outcome
        if err == nil {
            internalAddressBook = abUnmanaged?.takeRetainedValue()
        }
        else {
            accessError = err?.takeRetainedValue()
            return nil
        }
    }
    
    open class func authorizationStatus() -> ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }
    
    open class func requestAccessWithCompletion( _ completion : @escaping (Bool, CFError?) -> Void ) {
        ABAddressBookRequestAccessWithCompletion(nil, completion)
    }
    
    open func hasUnsavedChanges() -> Bool {
        return ABAddressBookHasUnsavedChanges(internalAddressBook)
    }
    
    open func save() -> CFError? {
        return errorIfNoSuccess { ABAddressBookSave(self.internalAddressBook, $0)}
    }
    
    open func revert() {
        ABAddressBookRevert(internalAddressBook)
    }
    
    open func addRecord(_ record : SwiftAddressBookRecord) -> CFError? {
        return errorIfNoSuccess { ABAddressBookAddRecord(self.internalAddressBook, record.internalRecord, $0) }
    }
    
    open func removeRecord(_ record : SwiftAddressBookRecord) -> CFError? {
        return errorIfNoSuccess { ABAddressBookRemoveRecord(self.internalAddressBook, record.internalRecord, $0) }
    }
    //MARK: person records
    
    open var personCount : Int {
        return ABAddressBookGetPersonCount(internalAddressBook)
    }
    
    open func personWithRecordId(_ recordId : Int32) -> SwiftAddressBookPerson? {
        return SwiftAddressBookPerson(record: ABAddressBookGetPersonWithRecordID(internalAddressBook, recordId)?.takeUnretainedValue())
    }
    
    open var allPeople : [SwiftAddressBookPerson]? {
        return convertRecordsToPersons(ABAddressBookCopyArrayOfAllPeople(internalAddressBook).takeRetainedValue())
    }
    
    //	open func registerExternalChangeCallback(_ callback: @escaping () -> Void) {
    //		addressBookObserver.startObserveChanges { (addressBook) -> Void in
    //			callback()
    //		}
    //	}
    //
    //	open func unregisterExternalChangeCallback(_ callback: () -> Void) {
    //		addressBookObserver.stopObserveChanges()
    //		callback()
    //	}
    
    
    
    open var allPeopleExcludingLinkedContacts : [SwiftAddressBookPerson]? {
        if let all = allPeople {
            let filtered : NSMutableArray = NSMutableArray(array: all)
            for person in all {
                if !(NSArray(array: filtered) as! [SwiftAddressBookPerson]).contains(where: {
                    (p : SwiftAddressBookPerson) -> Bool in
                    return p.recordID == person.recordID
                }) {
                    //already filtered out this contact
                    continue
                }
                
                //throw out duplicates
                let allFiltered : [SwiftAddressBookPerson] = NSArray(array: filtered) as! [SwiftAddressBookPerson]
                for possibleDuplicate in allFiltered {
                    if let linked = person.allLinkedPeople {
                        if possibleDuplicate.recordID != person.recordID
                            && linked.contains(where: {
                                (p : SwiftAddressBookPerson) -> Bool in
                                return p.recordID == possibleDuplicate.recordID
                            }) {
                            (filtered as NSMutableArray).remove(possibleDuplicate)
                        }
                    }
                }
            }
            return NSArray(array: filtered) as? [SwiftAddressBookPerson]
        }
        return nil
    }
    
    open func allPeopleInSource(_ source : SwiftAddressBookSource) -> [SwiftAddressBookPerson]? {
        return convertRecordsToPersons(ABAddressBookCopyArrayOfAllPeopleInSource(internalAddressBook, source.internalRecord).takeRetainedValue())
    }
    
    open func allPeopleInSourceWithSortOrdering(_ source : SwiftAddressBookSource, ordering : SwiftAddressBookOrdering) -> [SwiftAddressBookPerson]? {
        return convertRecordsToPersons(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(internalAddressBook, source.internalRecord, ordering.abPersonSortOrderingValue).takeRetainedValue())
    }
    
    open func peopleWithName(_ name : String) -> [SwiftAddressBookPerson]? {
        return convertRecordsToPersons(ABAddressBookCopyPeopleWithName(internalAddressBook, (name as CFString)).takeRetainedValue())
    }
    
    
    //MARK: group records
    
    open func groupWithRecordId(_ recordId : Int32) -> SwiftAddressBookGroup? {
        return SwiftAddressBookGroup(record: ABAddressBookGetGroupWithRecordID(internalAddressBook, recordId)?.takeUnretainedValue())
    }
    
    open var groupCount : Int {
        return ABAddressBookGetGroupCount(internalAddressBook)
    }
    
    open var arrayOfAllGroups : [SwiftAddressBookGroup]? {
        return convertRecordsToGroups(ABAddressBookCopyArrayOfAllGroups(internalAddressBook).takeRetainedValue())
    }
    
    open func allGroupsInSource(_ source : SwiftAddressBookSource) -> [SwiftAddressBookGroup]? {
        return convertRecordsToGroups(ABAddressBookCopyArrayOfAllGroupsInSource(internalAddressBook, source.internalRecord).takeRetainedValue())
    }
    
    
    //MARK: sources
    
    open var defaultSource : SwiftAddressBookSource? {
        return SwiftAddressBookSource(record: ABAddressBookCopyDefaultSource(internalAddressBook)?.takeRetainedValue())
    }
    
    open func sourceWithRecordId(_ sourceId : Int32) -> SwiftAddressBookSource? {
        return SwiftAddressBookSource(record: ABAddressBookGetSourceWithRecordID(internalAddressBook, sourceId)?.takeUnretainedValue())
    }
    
    open var allSources : [SwiftAddressBookSource]? {
        return convertRecordsToSources(ABAddressBookCopyArrayOfAllSources(internalAddressBook).takeRetainedValue())
    }
}
