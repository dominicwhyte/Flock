//
//  SwiftAddressBookPerson.swift
//  Pods
//
//  Created by Socialbit - Tassilo Karge on 09.03.15.
//
//

import UIKit
import AddressBook


@available(iOS, deprecated: 9.0)

//MARK: Wrapper for ABAddressBookRecord of type ABPerson

open class SwiftAddressBookPerson : SwiftAddressBookRecord {
    
    open class func create() -> SwiftAddressBookPerson {
        return SwiftAddressBookPerson(record: ABPersonCreate().takeRetainedValue())
    }
    
    open class func createInSource(_ source : SwiftAddressBookSource) -> SwiftAddressBookPerson {
        return SwiftAddressBookPerson(record: ABPersonCreateInSource(source.internalRecord).takeRetainedValue())
    }
    
    open class func createInSourceWithVCard(_ source : SwiftAddressBookSource, vCard : String) -> [SwiftAddressBookPerson]? {
        guard let data = vCard.data(using: .utf8, allowLossyConversion: true) else {
            return nil
        }
        let persons = ABPersonCreatePeopleInSourceWithVCardRepresentation(source.internalRecord, (data as CFData)).takeRetainedValue() as [ABRecord]
        var swiftPersons = [SwiftAddressBookPerson]()
        for person in persons {
            let swiftPerson = SwiftAddressBookPerson(record: person)
            swiftPersons.append(swiftPerson)
        }
        if swiftPersons.count != 0 {
            return swiftPersons
        }
        else {
            return nil
        }
    }
    
    open class func createVCard(_ people : [SwiftAddressBookPerson]) -> String {
        let peopleArray = people.flatMap { $0.internalRecord }
        let data = ABPersonCreateVCardRepresentationWithPeople(peopleArray as CFArray).takeRetainedValue() as Data
        return String(data: data, encoding: .utf8)!
    }
    
    open class func ordering() -> SwiftAddressBookOrdering {
        return SwiftAddressBookOrdering(ordering: ABPersonGetSortOrdering())
    }
    
    open class func comparePeopleByName(_ person1 : SwiftAddressBookPerson, person2 : SwiftAddressBookPerson, ordering : SwiftAddressBookOrdering) -> CFComparisonResult {
        return ABPersonComparePeopleByName(person1.internalRecord, person2.internalRecord, ordering.abPersonSortOrderingValue)
    }
    
    
    //MARK: Personal Information
    
    open func setImage(_ image : UIImage?) -> CFError? {
        guard let image = image else { return removeImage() }
        let imageData : Data = UIImagePNGRepresentation(image) ?? Data()
        return errorIfNoSuccess { ABPersonSetImageData(self.internalRecord,  CFDataCreate(nil, (imageData as NSData).bytes.bindMemory(to: UInt8.self, capacity: imageData.count), imageData.count), $0) }
    }
    
    open var image : UIImage? {
        guard ABPersonHasImageData(internalRecord) else { return nil }
        guard let data = ABPersonCopyImageData(internalRecord)?.takeRetainedValue() else { return nil }
        return UIImage(data: data as Data)
    }
    
    open func imageDataWithFormat(_ format : SwiftAddressBookPersonImageFormat) -> UIImage? {
        guard let data = ABPersonCopyImageDataWithFormat(internalRecord, format.abPersonImageFormat)?.takeRetainedValue() else {
            return nil
        }
        return UIImage(data: data as Data)
    }
    
    open func hasImageData() -> Bool {
        return ABPersonHasImageData(internalRecord)
    }
    
    open func removeImage() -> CFError? {
        return errorIfNoSuccess { ABPersonRemoveImageData(self.internalRecord, $0) }
    }
    
    open var allLinkedPeople : Array<SwiftAddressBookPerson>? {
        return convertRecordsToPersons(ABPersonCopyArrayOfAllLinkedPeople(internalRecord).takeRetainedValue())
    }
    
    open var source : SwiftAddressBookSource {
        return SwiftAddressBookSource(record: ABPersonCopySource(internalRecord).takeRetainedValue())
    }
    
    open var compositeNameDelimiterForRecord : String {
        return ABPersonCopyCompositeNameDelimiterForRecord(internalRecord).takeRetainedValue() as String
    }
    
    open var compositeNameFormat : SwiftAddressBookCompositeNameFormat {
        return SwiftAddressBookCompositeNameFormat(format: ABPersonGetCompositeNameFormatForRecord(internalRecord))
    }
    
    open var compositeName : String? {
        return ABRecordCopyCompositeName(internalRecord)?.takeRetainedValue() as String?
    }
    
    open var firstName : String? {
        get {
            return extractProperty(kABPersonFirstNameProperty)
        }
        set {
            setSingleValueProperty(kABPersonFirstNameProperty,  newValue as NSString?)
        }
    }
    
    open var lastName : String? {
        get {
            return extractProperty(kABPersonLastNameProperty)
        }
        set {
            setSingleValueProperty(kABPersonLastNameProperty,  newValue as NSString?)
        }
    }
    
    open var middleName : String? {
        get {
            return extractProperty(kABPersonMiddleNameProperty)
        }
        set {
            setSingleValueProperty(kABPersonMiddleNameProperty,  newValue as NSString?)
        }
    }
    
    open var prefix : String? {
        get {
            return extractProperty(kABPersonPrefixProperty)
        }
        set {
            setSingleValueProperty(kABPersonPrefixProperty,  newValue as NSString?)
        }
    }
    
    open var suffix : String? {
        get {
            return extractProperty(kABPersonSuffixProperty)
        }
        set {
            setSingleValueProperty(kABPersonSuffixProperty,  newValue as NSString?)
        }
    }
    
    open var nickname : String? {
        get {
            return extractProperty(kABPersonNicknameProperty)
        }
        set {
            setSingleValueProperty(kABPersonNicknameProperty,  newValue as NSString?)
        }
    }
    
    open var firstNamePhonetic : String? {
        get {
            return extractProperty(kABPersonFirstNamePhoneticProperty)
        }
        set {
            setSingleValueProperty(kABPersonFirstNamePhoneticProperty,  newValue as NSString?)
        }
    }
    
    open var lastNamePhonetic : String? {
        get {
            return extractProperty(kABPersonLastNamePhoneticProperty)
        }
        set {
            setSingleValueProperty(kABPersonLastNamePhoneticProperty,  newValue as NSString?)
        }
    }
    
    open var middleNamePhonetic : String? {
        get {
            return extractProperty(kABPersonMiddleNamePhoneticProperty)
        }
        set {
            setSingleValueProperty(kABPersonMiddleNamePhoneticProperty,  newValue as NSString?)
        }
    }
    
    open var organization : String? {
        get {
            return extractProperty(kABPersonOrganizationProperty)
        }
        set {
            setSingleValueProperty(kABPersonOrganizationProperty,  newValue as NSString?)
        }
    }
    
    open var jobTitle : String? {
        get {
            return extractProperty(kABPersonJobTitleProperty)
        }
        set {
            setSingleValueProperty(kABPersonJobTitleProperty,  newValue as NSString?)
        }
    }
    
    open var department : String? {
        get {
            return extractProperty(kABPersonDepartmentProperty)
        }
        set {
            setSingleValueProperty(kABPersonDepartmentProperty,  newValue as NSString?)
        }
    }
    
    open var emails : Array<MultivalueEntry<String>>? {
        get {
            return extractMultivalueProperty(kABPersonEmailProperty)
        }
        set {
            setMultivalueProperty(kABPersonEmailProperty, convertMultivalueEntries(newValue, converter: {  $0 as NSString }))
        }
    }
    
    open var birthday : Date? {
        get {
            return extractProperty(kABPersonBirthdayProperty)
        }
        set {
            setSingleValueProperty(kABPersonBirthdayProperty, newValue.map { $0 as CFDate})
        }
    }
    
    open var note : String? {
        get {
            return extractProperty(kABPersonNoteProperty)
        }
        set {
            setSingleValueProperty(kABPersonNoteProperty,  newValue as NSString?)
        }
    }
    
    open var creationDate : Date? {
        get {
            return extractProperty(kABPersonCreationDateProperty)
        }
        set {
            setSingleValueProperty(kABPersonCreationDateProperty, newValue.map { $0 as CFDate})
        }
    }
    
    open var modificationDate : Date? {
        get {
            return extractProperty(kABPersonModificationDateProperty)
        }
        set {
            setSingleValueProperty(kABPersonModificationDateProperty, newValue.map { $0 as CFDate})
        }
    }
    
    open var addresses : Array<MultivalueEntry<Dictionary<SwiftAddressBookAddressProperty,Any>>>? {
        get {
            let keyConverter = {(s : NSString) -> SwiftAddressBookAddressProperty in SwiftAddressBookAddressProperty(property: s as String)}
            let valueConverter = { (s : AnyObject) -> AnyObject in return s }
            return extractMultivalueDictionaryProperty(kABPersonAddressProperty, keyConverter: keyConverter, valueConverter: valueConverter)
        }
        set {
            setMultivalueDictionaryProperty(kABPersonAddressProperty, newValue, keyConverter: { $0.abAddressProperty as NSString }, valueConverter: { $0 } )
        }
    }
    
    open var dates : Array<MultivalueEntry<Date>>? {
        get {
            return extractMultivalueProperty(kABPersonDateProperty)
        }
        set {
            guard let someValue = newValue else {
                return
            }
            
            let mappedValues = someValue.map { MultivalueEntry(value: ($0.value as CFDate), label: $0.label, id: $0.id) }
            setMultivalueProperty(kABPersonDateProperty, mappedValues)
        }
    }
    
    open var type : SwiftAddressBookPersonType {
        get {
            return SwiftAddressBookPersonType(type : extractProperty(kABPersonKindProperty))
        }
        set {
            setSingleValueProperty(kABPersonKindProperty, newValue.abPersonType)
        }
    }
    
    open var phoneNumbers : Array<MultivalueEntry<String>>? {
        get {
            return extractMultivalueProperty(kABPersonPhoneProperty)
        }
        set {
            setMultivalueProperty(kABPersonPhoneProperty, convertMultivalueEntries(newValue, converter: { $0 as NSString}))
        }
    }
    
    open var instantMessage : Array<MultivalueEntry<Dictionary<SwiftAddressBookInstantMessagingProperty,String>>>? {
        get {
            let keyConverter = {(s : NSString) -> SwiftAddressBookInstantMessagingProperty in SwiftAddressBookInstantMessagingProperty(property: s as String)}
            let valueConverter = { (s : String) -> String in return s }
            return extractMultivalueDictionaryProperty(kABPersonInstantMessageProperty, keyConverter: keyConverter, valueConverter: valueConverter)
        }
        set {
            setMultivalueDictionaryProperty(kABPersonInstantMessageProperty, newValue, keyConverter: {  $0.abInstantMessageProperty as NSString }, valueConverter: {  $0 as NSString })
        }
    }
    
    open var socialProfiles : Array<MultivalueEntry<Dictionary<SwiftAddressBookSocialProfileProperty,String>>>? {
        get {
            let keyConverter = {(s : NSString) -> SwiftAddressBookSocialProfileProperty in SwiftAddressBookSocialProfileProperty(property: s as String)}
            let valueConverter = { (s : String) -> String in return s }
            return extractMultivalueDictionaryProperty(kABPersonSocialProfileProperty, keyConverter: keyConverter, valueConverter: valueConverter)
        }
        set {
            setMultivalueDictionaryProperty(kABPersonSocialProfileProperty, newValue, keyConverter: {  $0.abSocialProfileProperty as NSString }, valueConverter:  {  $0 as NSString } )
        }
    }
    
    
    open var urls : Array<MultivalueEntry<String>>? {
        get {
            return extractMultivalueProperty(kABPersonURLProperty)
        }
        set {
            setMultivalueProperty(kABPersonURLProperty, convertMultivalueEntries(newValue, converter: {  $0 as NSString }))
        }
    }
    
    open var relatedNames : Array<MultivalueEntry<String>>? {
        get {
            return extractMultivalueProperty(kABPersonRelatedNamesProperty)
        }
        set {
            setMultivalueProperty(kABPersonRelatedNamesProperty, convertMultivalueEntries(newValue, converter: {  $0 as NSString }))
        }
    }
    
    open var alternateBirthday : Dictionary<String, AnyObject>? {
        get {
            return extractProperty(kABPersonAlternateBirthdayProperty)
        }
        set {
            let dict : NSDictionary? = newValue as NSDictionary?
            setSingleValueProperty(kABPersonAlternateBirthdayProperty, dict)
        }
    }
    
    
    //MARK: generic methods to set and get person properties
    
    fileprivate func extractProperty<T>(_ propertyName : ABPropertyID) -> T? {
        //the following is two-lines of code for a reason. Do not combine (compiler optimization problems)
        let value: AnyObject? = ABRecordCopyValue(self.internalRecord, propertyName)?.takeRetainedValue()
        return value as? T
    }
    
    fileprivate func setSingleValueProperty<T : AnyObject>(_ key : ABPropertyID,_ value : T?) {
        ABRecordSetValue(self.internalRecord, key, value, nil)
    }
    
    fileprivate func extractMultivalueProperty<T>(_ propertyName : ABPropertyID) -> Array<MultivalueEntry<T>>? {
        guard let multivalue: ABMultiValue = extractProperty(propertyName) else { return nil }
        var array = Array<MultivalueEntry<T>>()
        for i : Int in 0..<(ABMultiValueGetCount(multivalue)) {
            let value : T? = ABMultiValueCopyValueAtIndex(multivalue, i).takeRetainedValue() as? T
            if let v : T = value {
                let id : Int = Int(ABMultiValueGetIdentifierAtIndex(multivalue, i))
                let optionalLabel = ABMultiValueCopyLabelAtIndex(multivalue, i)?.takeRetainedValue()
                array.append(MultivalueEntry(value: v,
                                             label: optionalLabel == nil ? nil : optionalLabel! as String,
                                             id: id))
            }
        }
        return !array.isEmpty ? array : nil
    }
    
    fileprivate func extractMultivalueDictionaryProperty<T : NSCopying, U, V, W>(_ propertyName : ABPropertyID, keyConverter : (T) -> V, valueConverter : (U) -> W ) -> Array<MultivalueEntry<Dictionary<V, W>>>? {
        
        let property : Array<MultivalueEntry<NSDictionary>>? = extractMultivalueProperty(propertyName)
        if let array = property {
            
            var array2 : Array<MultivalueEntry<Dictionary<V, W>>> = []
            for oldValue in array {
                let mv = MultivalueEntry(value: convertNSDictionary(oldValue.value, keyConverter: keyConverter, valueConverter: valueConverter)!, label: oldValue.label, id: oldValue.id)
                array2.append(mv);
            }
            return array2
            
        }
        else {
            return nil
        }
    }
    
    fileprivate func convertNSDictionary<T : NSCopying, U, V, W>(_ d : NSDictionary?, keyConverter : (T) -> V, valueConverter : (U) -> W ) -> Dictionary<V, W>? {
        if let d2 = d {
            var dict = Dictionary<V,W>()
            for key in d2.allKeys as! Array<T> {
                let newKey = keyConverter(key)
                let newValue = valueConverter(d2[key] as! U)
                dict[newKey] = newValue
            }
            return dict
        }
        else {
            return nil
        }
    }
    
    fileprivate func convertMultivalueEntries<T,U: AnyObject>(_ multivalue : [MultivalueEntry<T>]?, converter : (T) -> U) -> [MultivalueEntry<U>]? {
        
        var result: [MultivalueEntry<U>]?
        if let multivalue = multivalue {
            result = []
            for m in multivalue {
                let convertedValue = converter(m.value)
                let converted = MultivalueEntry(value: convertedValue, label: m.label, id: m.id)
                result?.append(converted)
            }
        }
        return result
    }
    
    fileprivate func setMultivalueProperty<T : AnyObject>(_ key : ABPropertyID,_ multivalue : Array<MultivalueEntry<T>>?) {
        if(multivalue == nil) {
            let emptyMultivalue: ABMutableMultiValue = ABMultiValueCreateMutable(ABPersonGetTypeOfProperty(key)).takeRetainedValue()
            //TODO: handle possible error
            _ = errorIfNoSuccess { ABRecordSetValue(self.internalRecord, key, emptyMultivalue, $0) }
            return
        }
        
        var abmv : ABMutableMultiValue? = nil
        
        /* make mutable copy to be able to update multivalue */
        if let oldValue : ABMultiValue = extractProperty(key) {
            abmv = ABMultiValueCreateMutableCopy(oldValue)?.takeRetainedValue()
        }
        
        var abmv2 : ABMutableMultiValue? = abmv
        
        /* initialize abmv for sure */
        if abmv2 == nil {
            abmv2 = ABMultiValueCreateMutable(ABPersonGetTypeOfProperty(key)).takeRetainedValue()
        }
        
        let abMultivalue: ABMutableMultiValue = abmv2!
        
        var identifiers = Array<Int>()
        
        for i : Int in 0..<(ABMultiValueGetCount(abMultivalue)) {
            identifiers.append(Int(ABMultiValueGetIdentifierAtIndex(abMultivalue, i)))
        }
        
        for m : MultivalueEntry in multivalue! {
            if identifiers.contains(m.id) {
                let index = ABMultiValueGetIndexForIdentifier(abMultivalue, Int32(m.id))
                ABMultiValueReplaceValueAtIndex(abMultivalue, m.value, index)
                ABMultiValueReplaceLabelAtIndex(abMultivalue, m.label as CFString!, index)
                identifiers.remove(at: identifiers.index(of: m.id)!)
            }
            else {
                ABMultiValueAddValueAndLabel(abMultivalue, m.value, m.label as CFString!, nil)
            }
        }
        
        for i in identifiers {
            ABMultiValueRemoveValueAndLabelAtIndex(abMultivalue, ABMultiValueGetIndexForIdentifier(abMultivalue,Int32(i)))
        }
        
        ABRecordSetValue(internalRecord, key, abMultivalue, nil)
    }
    
    fileprivate func setMultivalueDictionaryProperty<KeyType, ValueType, TargetKeyType: Hashable, TargetValueType: Any>
        (_ key : ABPropertyID, _ multivalue : Array<MultivalueEntry<Dictionary<KeyType,ValueType>>>?,keyConverter : @escaping (KeyType) -> TargetKeyType, valueConverter : @escaping (ValueType) -> TargetValueType) {
        
        let array = convertMultivalueEntries(multivalue, converter: { d -> NSDictionary in
            var dict = Dictionary<TargetKeyType,TargetValueType>()
            for key in d.keys {
                dict[keyConverter(key)] = valueConverter(d[key]!)
            }
            return (dict as NSDictionary?)!
        })
        
        setMultivalueProperty(key, array)
    }
}
