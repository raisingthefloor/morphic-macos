// Copyright 2020-2025 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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
import MorphicCore

public class AccessibilityDisplaySettings {
    public static func getIncreaseContrastIsEnabled() throws -> Bool? {
        let result = try UserDefaultsUtils.defaultAsOptionalBool(suiteName: "com.apple.universalaccess", forKey: "increaseContrast")
        return result
    }
    
    //
    
    public static func getReduceTransparencyIsEnabled() throws -> Bool? {
        let result = try UserDefaultsUtils.defaultAsOptionalBool(suiteName: "com.apple.universalaccess", forKey: "reduceTransparency")
        return result
    }
    
    //
    
    public enum ColorFilterType {
        case grayscale // = 1
        case protanopia // = 2 (red/green filter)
        case deuteranopia // = 4 (green/red filter)
        case tritanopia // = 8 (blue/yellow filter)
        case colorTint // = 16
        case other(value: Int)
        
        public init(fromIntValue value: Int) {
            switch value {
            case 1:
                self = .grayscale
            case 2:
                self = .protanopia
            case 4:
                self = .deuteranopia
            case 8:
                self = .tritanopia
            case 16:
                self = .colorTint
            default:
                self = .other(value: value)
            }
        }
        
        public init?(fromStringValue value: String) {
            switch value {
            case "Grayscale":
                self = .grayscale
            case "Red/Green filter (Protanopia)":
                self = .protanopia
            case "Green/Red filter (Deuteranopia)":
                self = .deuteranopia
            case "Blue/Yellow filter (Tritanopia)":
                self = .tritanopia
            case "Color Tint":
                self = .colorTint
            default:
                return nil
            }
        }

        public var intValue: Int {
            get {
                switch self {
                case .grayscale:
                    return 1
                case .protanopia:
                    return 2
                case .deuteranopia:
                    return 4
                case .tritanopia:
                    return 8
                case .colorTint:
                    return 16
                case .other(let value):
                    return value
                }
            }
        }
        
        public var stringValue: String? {
            get {
                switch self {
                case .grayscale:
                    return "Grayscale"
                case .protanopia:
                    return "Red/Green filter (Protanopia)"
                case .deuteranopia:
                    return "Green/Red filter (Deuteranopia)"
                case .tritanopia:
                    return "Blue/Yellow filter (Tritanopia)"
                case .colorTint:
                    return "Color Tint"
                case .other(_):
                    return nil
                }
            }
        }
    }
    
    public static func getColorFilterType() throws -> ColorFilterType? {
        guard let resultAsInt = try UserDefaultsUtils.defaultAsOptionalInt(suiteName: "com.apple.mediaaccessibility", forKey: "__Color__-MADisplayFilterType") else {
            return nil
        }
        
        let result = ColorFilterType(fromIntValue: resultAsInt)
        return result
    }
    
    public static func getColorFiltersAreEnabled() throws -> Bool? {
        let result = try UserDefaultsUtils.defaultAsOptionalBool(suiteName: "com.apple.mediaaccessibility", forKey: "__Color__-MADisplayFilterCategoryEnabled")
        return result
    }
    
    //
    
    public enum InvertColorsMode {
        case classic
        case smart
    }
}
