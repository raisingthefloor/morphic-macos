// Copyright 2020-2025 Raising the Floor - International
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
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "DefaultsReadUIWrite")

/// A setting handler that reads values from user defaults, but writes values using the system preferences UI
///
/// The asymmetry between read and write is because macOS won't let us write the user defaults directly (sometimes because we don't have Full Trust, sometimes because of SIP).
/// Additionally, several system settings checkboxes actually change more than one default and call private functions that we don't have access to, so using the UI is the best option.
public class DefaultsReadUIWriteSettingHandler: SettingHandler {
    
    public required init(setting: Setting) {
        super.init(setting: setting)
        defaults = UserDefaults(suiteName: description.defaultsDomain)
    }
    
    /// The user defaults object to use, based on the `defaultsDomain` from the setting's `handlerDescription`
    private var defaults: UserDefaults?
    
    /// The data model describing the properties for this kind of setting handler
    public struct Description: SettingHandlerDescription {
        
        public var type: Setting.HandlerType {
            return .defaultsReadUIWrite
        }
        
        /// The user defaults domain to read from
        public let defaultsDomain: String
        
        /// The user defaults key within the domain that stores the actual value
        public let defaultsKey: String
        
//        public let ui: UIDescription
        
        public let solution: String
        public let preference: String
        
        public let transform: Transform?
        
        public enum Transform: String, Decodable {
            case negateBoolean
        }
        
        public enum CodingKeys: String, CodingKey {
            case defaultsDomain = "defaults_domain"
            case defaultsKey = "defaults_key"
            case solution
            case preference
            case transform
//            case ui
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            defaultsDomain = try container.decode(String.self, forKey: .defaultsDomain)
            defaultsKey = try container.decode(String.self, forKey: .defaultsKey)
//            ui = try container.decode(String.self, forKey: .ui)
            solution = try container.decode(String.self, forKey: .solution)
            preference = try container.decode(String.self, forKey: .preference)
            transform = try container.decodeIfPresent(Transform.self, forKey: .transform)
        }
    }
    
//    public struct UIDescription: Decodable {
//
//        public let steps: [Step]
//
//        public enum CodingKeys: String, CodingKey {
//            case steps
//        }
//
//        public init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            steps = try container.decode([Step].self, forKey: .steps)
//        }
//
//    }
//
//    public struct Step: Decodable {
//        public var action: String
//        public var identifier: String
//
//        public enum CodingKeys: String, CodingKey {
//            case action
//            case identifier
//        }
//
//        public init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            action = try container.decode(String.self, forKey: .action)
//            identifier = try container.decode(String.self, forKey: .identifier)
//        }
//
//        public func action(for value: Interoperable?) -> UIElement.Action? {
//            switch action {
//            case "launch":
//                return .launch(bundleIdentifier: identifier)
//            case "press":
//                return .press(buttonTitle: identifier)
//            case "show":
//                return .show(identifier: identifier)
//            case "check":
//                guard let checked = value as? Bool else {
//                    return nil
//                }
//                return .check(checkboxTitle: identifier, checked: checked)
//            default:
//                return nil
//            }
//        }
//    }
    
    /// The properly typed description for this handler
    private var description: Description {
        return setting.handlerDescription as! Description
    }

    //
    
    private static var uiAutomationSetSettingProxyTypesByKey = [Preferences.Key: UIAutomationSetSettingProxy.Type]()
    
    public static func register(uiAutomationSetSettingProxy: UIAutomationSetSettingProxy.Type, for key: Preferences.Key) {
        uiAutomationSetSettingProxyTypesByKey[key] = uiAutomationSetSettingProxy
    }

    public static func uiAutomationSetSettingProxy(for key: Preferences.Key) -> UIAutomationSetSettingProxy? {
        guard let type = uiAutomationSetSettingProxyTypesByKey[key] else {
            return nil
        }
        return type.init()
    }

    //
    
    public override func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void) {
        let key = Preferences.Key(solution: description.solution, preference: description.preference)
        
        if let uiAutomationSetSettingProxy = DefaultsReadUIWriteSettingHandler.uiAutomationSetSettingProxy(for: key) {
            // transitional ui set setting proxy automation (macOS 13 and newer)

            Task {
                do {
                    try await uiAutomationSetSettingProxy.apply(value)
                } catch {
                    // if the operation fails, call the completion handler with a failure result
                    completion(false)
                    return
                }

                // if we reach here, the operation was successful
                completion(true)
                return
            }
        } else {
            completion(false)
            return
        }
    }
    
    public override func read(completion: @escaping (_ result: SettingHandler.Result) -> Void) {
        switch setting.type {
        case .boolean:
            guard var boolValue = defaults?.bool(forKey: description.defaultsKey) else{
                completion(.failed)
                return
            }
            if let transform = description.transform {
                switch transform {
                case .negateBoolean:
                    boolValue = !boolValue
                }
            }
            completion(.succeeded(value: boolValue))
        case .double:
            guard let doubleValue = defaults?.double(forKey: description.defaultsKey) else {
                completion(.failed)
                return
            }
            completion(.succeeded(value: doubleValue))
        case .integer:
            guard let intValue = defaults?.integer(forKey: description.defaultsKey) else {
                completion(.failed)
                return
            }
            completion(.succeeded(value: intValue))
        case .string:
            guard let stringValue = defaults?.string(forKey: description.defaultsKey) else {
                completion(.failed)
                return
            }
            completion(.succeeded(value: stringValue))
        }
    }
    
}
