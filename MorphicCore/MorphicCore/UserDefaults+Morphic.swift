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

public extension UserDefaults {
    private struct MorphicUserDefaultsStaticValues {
        // NOTE: we intentionally make suiteName an optional so that we detect if it hasn't been configured
        static var suiteName: String? = nil
    }

    static func setMorphicSuiteName(_ suiteName: String) {
        MorphicUserDefaultsStaticValues.suiteName = suiteName
    }
    
    static var morphic: UserDefaults {
        // NOTE: if morphicSuiteName has not been set, this will intentionally assert; the caller must ALWAYS set the suite name beforehand
        return UserDefaults(suiteName: MorphicUserDefaultsStaticValues.suiteName!)!
    }
    
    func morphicUsername(for userIdentifier: String) -> String? {
        let usernamesByIdentifier = dictionary(forKey: .morphicDefaultsKeyUsernamesByIdentifier)
        return usernamesByIdentifier?[userIdentifier] as? String
    }
    
    func set(morphicUsername: String, for userIdentifier: String) {
        var usernamesByIdentifier = dictionary(forKey: .morphicDefaultsKeyUsernamesByIdentifier) ?? [String: Any]()
        usernamesByIdentifier[userIdentifier] = morphicUsername
        setValue(usernamesByIdentifier, forKey: .morphicDefaultsKeyUsernamesByIdentifier)
    }
    
    func selectedUserCommunityId(for userIdentifier: String) -> String? {
        let userCommunityIdentifiersByUserIdentifier = dictionary(forKey: .morphicDefaultsKeyUserCommunityIdentifiersByUserIdentifier)
        return userCommunityIdentifiersByUserIdentifier?[userIdentifier] as? String
    }
    
    func set(selectedUserCommunityIdentifier: String?, for userIdentifier: String) {
        var userCommunityIdentifiersByUserIdentifier = dictionary(forKey: .morphicDefaultsKeyUserCommunityIdentifiersByUserIdentifier) ?? [String : Any]()
        userCommunityIdentifiersByUserIdentifier[userIdentifier] = selectedUserCommunityIdentifier
        setValue(userCommunityIdentifiersByUserIdentifier, forKey: .morphicDefaultsKeyUserCommunityIdentifiersByUserIdentifier)
    }
    
    func selectedMorphicbarId(for userIdentifier: String) -> String? {
        let morphicbarIdentifiersByUserIdentifier = dictionary(forKey: .morphicDefaultsKeyMorphicbarIdentifiersByUserIdentifier)
        return morphicbarIdentifiersByUserIdentifier?[userIdentifier] as? String
    }

    func set(selectedMorphicbarIdentifier: String?, for userIdentifier: String) {
        var morphicbarIdentifiersByUserIdentifier = dictionary(forKey: .morphicDefaultsKeyMorphicbarIdentifiersByUserIdentifier) ?? [String : Any]()
        morphicbarIdentifiersByUserIdentifier[userIdentifier] = selectedMorphicbarIdentifier
        setValue(morphicbarIdentifiersByUserIdentifier, forKey: .morphicDefaultsKeyMorphicbarIdentifiersByUserIdentifier)
    }

    func telemetryDeviceUuid() -> String? {
        return string(forKey: .morphicDefaultsKeyTelemetryDeviceUuid)
    }
    
    func set(telemetryDeviceUuid: String?) {
        setValue(telemetryDeviceUuid, forKey: .morphicDefaultsKeyTelemetryDeviceUuid)
    }
}

public extension String {
    static var morphicDefaultsKeyMorphicbarIdentifiersByUserIdentifier = "morphicbarIdentifiersByUserIdentifier"
    static var morphicDefaultsKeyUserIdentifier = "userIdentifier"
    static var morphicDefaultsKeyUsernamesByIdentifier = "usernamesByIdentifier"
    static var morphicDefaultsKeyUserCommunityIdentifiersByUserIdentifier = "userCommunityIdentifiersByUserIdentifier"
    static var morphicDefaultsKeyTelemetryDeviceUuid = "telemetryDeviceUuid"
}
