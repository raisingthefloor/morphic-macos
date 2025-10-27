// Copyright 2020 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation

// NOTE: the MorphicPropertyList class contains the functionality used by Obj-C and Swift applications

// Property list data types are documented at:
// https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/PropertyList.html

public struct MorphicPropertyList {
    let dictionary: NSMutableDictionary
    
    public enum MorphicPropertyListError: Error {
        case invalidCast
    }
    
    // MARK: initializer (load)
    
    public init?(url: URL) {
        guard let dictionary = NSMutableDictionary(contentsOf: url) else {
            return nil
        }
        
        self.dictionary = dictionary
    }
    
    // MARK: value

//    public func value(forKey key: String) -> Any? {
//        return valueAsAny(forKey: key)
//    }
    
    public func value<TElement>(forKey key: String) throws -> Array<TElement>? where TElement: PropertyListValueCompatible {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let resultAsNSArray = resultAsAny as? NSArray else {
            throw MorphicPropertyListError.invalidCast
        }
        guard let result = resultAsNSArray as? Array<TElement> else {
            throw MorphicPropertyListError.invalidCast
        }
        
        return result
    }

    public func value<TValue>(forKey key: String) throws -> Dictionary<String, TValue>? where TValue: PropertyListValueCompatible {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let resultAsNSDictionary = resultAsAny as? NSDictionary else {
            throw MorphicPropertyListError.invalidCast
        }
        guard let result = resultAsNSDictionary as? Dictionary<String, TValue> else {
            throw MorphicPropertyListError.invalidCast
        }
        
//        // NOTE: if we have problems casting using "as? Dictionary<String, TValue>" then try:
//        var result = Dictionary<String, TValue>()
//        let allKeys = resultAsNSDictionary.allKeys as! [String]
//        for key in allKeys {
//            guard let value = resultAsNSDictionary.value(forKey: key) as? TValue else {
//                throw MorphicPropertyListError.invalidCast
//            }
//            result[key] = value
//        }
        
        return result
    }

    public func value(forKey key: String) throws -> String? {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let resultAsNSString = resultAsAny as? NSString else {
            throw MorphicPropertyListError.invalidCast
        }
        let result = resultAsNSString as String
        
        return result
    }

    public func value(forKey key: String) throws -> Data? {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let resultAsNSData = resultAsAny as? NSData else {
            throw MorphicPropertyListError.invalidCast
        }
        let result = resultAsNSData as Data

        return result
    }

    public func value(forKey key: String) throws -> Date? {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let resultAsNSDate = resultAsAny as? NSDate else {
            throw MorphicPropertyListError.invalidCast
        }
        let result = resultAsNSDate as Date
        
        return result
    }

//    public func value(forKey key: String) throws -> NSNumber? {
//        let result: NSNumber? = try valueAsNSNumber(forKey: key)
//        return result
//    }

    public func value(forKey key: String) throws -> Int32? {
        guard let resultAsNSNumber: NSNumber = try valueAsNSNumber(forKey: key) else {
            return nil
        }
        guard let result = resultAsNSNumber as? Int32 else {
            throw MorphicPropertyListError.invalidCast
        }

        return result
    }

    public func value(forKey key: String) throws -> Int64? {
        guard let resultAsNSNumber: NSNumber = try valueAsNSNumber(forKey: key) else {
            return nil
        }
        guard let result = resultAsNSNumber as? Int64 else {
            throw MorphicPropertyListError.invalidCast
        }

        return result
    }

    public func value(forKey key: String) throws -> Float? {
        guard let resultAsNSNumber: NSNumber = try valueAsNSNumber(forKey: key) else {
            return nil
        }
        guard let result = resultAsNSNumber as? Float else {
            throw MorphicPropertyListError.invalidCast
        }

        return result
    }

    public func value(forKey key: String) throws -> Double? {
        guard let resultAsNSNumber: NSNumber = try valueAsNSNumber(forKey: key) else {
            return nil
        }
        guard let result = resultAsNSNumber as? Double else {
            throw MorphicPropertyListError.invalidCast
        }

        return result
    }

    public func value(forKey key: String) throws -> Bool? {
        guard let resultAsNSNumber: NSNumber = try valueAsNSNumber(forKey: key) else {
            return nil
        }
        guard let result = resultAsNSNumber as? Bool else {
            throw MorphicPropertyListError.invalidCast
        }

        return result
    }

    //
    
    private func valueAsAny(forKey key: String) -> Any? {
        return self.dictionary.object(forKey: key)
    }

    private func valueAsNSNumber(forKey key: String) throws -> NSNumber? {
        guard let resultAsAny = valueAsAny(forKey: key) else {
            return nil
        }
        guard let result = resultAsAny as? NSNumber else {
            throw MorphicPropertyListError.invalidCast
        }
        
        return result
    }

    // MARK: setValue

//    public func setValue(_ value: Any, forKey key: String) {
//        self.dictionary[key] = value
//    }

    public func setValue<TElement>(_ value: Array<TElement>, forKey key: String) where TElement: PropertyListValueCompatible {
        self.dictionary[key] = value as NSArray
    }

    public func setValue<TValue>(_ value: Dictionary<String, TValue>, forKey key: String) where TValue: PropertyListValueCompatible {
        self.dictionary[key] = value as NSDictionary
    }

    public func setValue(_ value: String, forKey key: String) {
        self.dictionary[key] = value as NSString
    }

    public func setValue(_ value: Data, forKey key: String) {
        self.dictionary[key] = value as NSData
    }

    public func setValue(_ value: Date, forKey key: String) {
        self.dictionary[key] = value as NSDate
    }

//    public func setValue(_ value: NSNumber, forKey key: String) {
//        self.dictionary[key] = value
//    }

    public func setValue(_ value: Int32, forKey key: String) {
        self.dictionary[key] = NSNumber(value: value)
    }

    public func setValue(_ value: Int64, forKey key: String) {
        self.dictionary[key] = NSNumber(value: value)
    }

    public func setValue(_ value: Float, forKey key: String) {
        self.dictionary[key] = NSNumber(value: value)
    }

    public func setValue(_ value: Double, forKey key: String) {
        self.dictionary[key] = NSNumber(value: value)
    }

    public func setValue(_ value: Bool, forKey key: String) {
        self.dictionary[key] = NSNumber(value: value)
    }

    // MARK: save

    public func saveAs(url: URL) throws {
        try self.dictionary.write(to: url)
    }
}

/* PropertyListValueCompatible marks specific classes as compatible to be property list values (for dictionaries, arrays, etc.) */
public protocol PropertyListValueCompatible { }
//
extension String: PropertyListValueCompatible { }
extension Data: PropertyListValueCompatible { }
extension Date: PropertyListValueCompatible { }
extension Int32: PropertyListValueCompatible { }
extension Int64: PropertyListValueCompatible { }
extension Float: PropertyListValueCompatible { }
extension Double: PropertyListValueCompatible { }
extension Bool: PropertyListValueCompatible { }
