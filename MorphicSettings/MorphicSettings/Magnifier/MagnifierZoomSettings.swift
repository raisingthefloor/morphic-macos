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

import Carbon.HIToolbox
import Foundation
import MorphicCore
import MorphicMacOSNative

public class MagnifierZoomSettings {
    public static func getHotkeysEnabled() throws -> Bool? {
        let result = try UserDefaultsUtils.defaultAsOptionalBool(suiteName: "com.apple.universalaccess", forKey: "closeViewHotkeysEnabled")
        return result
    }
    
    //
    
    public static func getMagnifierEnabled() throws -> Bool? {
        let result = try UserDefaultsUtils.defaultAsOptionalBool(suiteName: "com.apple.universalaccess", forKey: "closeViewZoomedIn")
        return result
    }
    
    public static func setMagnifierEnabled(_ value: Bool) throws {
        let currentValueAsOptional = try MagnifierZoomSettings.getMagnifierEnabled()
        guard let currentValue = currentValueAsOptional else {
            throw MorphicError.unspecified
        }
        
        if currentValue != value {
            try MagnifierZoomSettings.sendMagnifierToggleZoomHotkey()
        }
    }
    
    //
    
    public enum ZoomStyle {
        case fullScreen // = 0
        case pictureInPicture // = 1
        case splitScreen // = 2
        case other(value: Int)
        
        public init(fromIntValue value: Int) {
            switch value {
            case 0:
                self = .fullScreen
            case 1:
                self = .pictureInPicture
            case 2:
                self = .splitScreen
            default:
                self = .other(value: value)
            }
        }
        
        public init?(fromStringValue value: String) {
            switch value {
            case "Full Screen":
                self = .fullScreen
            case "Split Screen":
                self = .splitScreen
            case "Picture-in-Picture":
                self = .pictureInPicture
            default:
                return nil
            }
        }

        public var intValue: Int {
            get {
                switch self {
                case .fullScreen:
                    return 0
                case .pictureInPicture:
                    return 1
                case .splitScreen:
                    return 2
                case .other(let value):
                    return value
                }
            }
        }
        
        public var stringValue: String? {
            get {
                switch self {
                case .fullScreen:
                    return "Full Screen"
                case .splitScreen:
                    return "Split Screen"
                case .pictureInPicture:
                    return "Picture-in-Picture"
                case .other(_):
                    return nil
                }
            }
        }
    }
    
    public static func getZoomStyle() throws -> ZoomStyle? {
        let resultAsOptionalInt = try UserDefaultsUtils.defaultAsOptionalInt(suiteName: "com.apple.universalaccess", forKey: "closeViewZoomMode")
        guard let resultAsInt = resultAsOptionalInt else {
            return nil
        }
        
        let result = ZoomStyle(fromIntValue: resultAsInt)
        return result
    }

    //
    
    public static func sendMagnifierToggleZoomHotkey() throws {
        // verify that we have accessibility permissions (since sendKey will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            throw MorphicError.unspecified
        }
        
        try MorphicInput.sendKey(keyCode: CGKeyCode(kVK_ANSI_8), keyOptions: [.withCommandKey, .withAlternateKey], inputEventSource: .loginSession)
    }
}
