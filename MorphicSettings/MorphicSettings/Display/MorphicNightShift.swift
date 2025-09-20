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

public struct MorphicNightShift {
    public enum NightShiftScheduleMode: Int {
        case off = 0
        case sunsetToSunrise = 1
        case custom = 2
    }

    public struct NightShiftSchedule {
        public let from: (hour: Int, minute: Int)
        public let to: (hour: Int, minute: Int)
        
        public init(from: (hour: Int, minute: Int), to: (hour: Int, minute: Int)) {
            self.from = from
            self.to = to
        }
    }

    // NOTE: "active" means that the feature is allowed; if active==false then ENABLED has no effect
    public static func getActive() -> Bool {
        let blueLightClient = CBBlueLightClient()
        
        var blueLightStatus = CBBlueLight_Status()
        blueLightClient.getBlueLightStatus(&blueLightStatus)
        
        return blueLightStatus.active.boolValue
    }
    //
    public static func setActive(_ active: Bool) {
        let blueLightClient = CBBlueLightClient()
        blueLightClient.setActive(active)
    }
    
    public static func getLocationPermissionGranted() -> Bool {
        let blueLightClient = CBBlueLightClient()
        
        var blueLightStatus = CBBlueLight_Status()
        blueLightClient.getBlueLightStatus(&blueLightStatus)
        
        return blueLightStatus.locationPermissionGranted.boolValue
    }

    // NOTE: "enabled" means that the feature is currently in effect; however if active==false then ENABLED has no effect
    // NOTE: the "enabled" state corresponds to the "Manual" checkbox in System Preferences > ... > Night Shift (but "manual" is really a toggle, auto-updated if triggered by sunset/sunrise)
    public static func getEnabled() -> Bool {
        let blueLightClient = CBBlueLightClient()
        
        var blueLightStatus = CBBlueLight_Status()
        blueLightClient.getBlueLightStatus(&blueLightStatus)
        
        return blueLightStatus.enabled.boolValue
    }
    //
    public static func setEnabled(_ enabled: Bool) {
        let blueLightClient = CBBlueLightClient()
        blueLightClient.setEnabled(enabled)
    }

    public static func getScheduleMode() -> NightShiftScheduleMode? {
        let blueLightClient = CBBlueLightClient()
        
        var blueLightStatus = CBBlueLight_Status()
        blueLightClient.getBlueLightStatus(&blueLightStatus)
        
        return NightShiftScheduleMode(rawValue: Int(blueLightStatus.mode))
    }
    //
    public static func setScheduleMode(_ mode: NightShiftScheduleMode) {
        let blueLightClient = CBBlueLightClient()
        blueLightClient.setMode(Int32(mode.rawValue))
    }

    public static func getSchedule() -> NightShiftSchedule {
        let blueLightClient = CBBlueLightClient()
        
        var blueLightStatus = CBBlueLight_Status()
        blueLightClient.getBlueLightStatus(&blueLightStatus)
        
        let result = NightShiftSchedule(
            from: (hour: Int(blueLightStatus.schedule.from.hour), minute: Int(blueLightStatus.schedule.from.minute)),
            to: (hour: Int(blueLightStatus.schedule.to.hour), minute: Int(blueLightStatus.schedule.to.minute))
        )
        return result
    }
    //
    public static func setSchedule(_ schedule: NightShiftSchedule) {
        precondition(schedule.from.hour >= 0 && schedule.from.hour <= 23, "Argument 'schedule.from.hour' is out of the allowed range 0...23")
        precondition(schedule.from.minute >= 0 && schedule.from.minute <= 59, "Argument 'schedule.from.minute' is out of the allowed range 0...59")
        precondition(schedule.to.hour >= 0 && schedule.to.hour <= 23, "Argument 'schedule.to.hour' is out of the allowed range 0...23")
        precondition(schedule.to.minute >= 0 && schedule.to.minute <= 59, "Argument 'schedule.to.minute' is out of the allowed range 0...59")

        let blueLightClient = CBBlueLightClient()
        
        var schedule = CBBlueLight_Schedule(
            from: CBBlueLight_ScheduleTime(hour: Int32(schedule.from.hour), minute: Int32(schedule.from.minute)),
            to: CBBlueLight_ScheduleTime(hour: Int32(schedule.to.hour), minute: Int32(schedule.to.minute))
        )
        blueLightClient.setSchedule(&schedule)
    }

    public static func getColorTemperature() -> Float {
        let blueLightClient = CBBlueLightClient()
        
        var strength = Float()
        blueLightClient.getStrength(&strength)
        
        return strength
    }

    // NOTE: if "overrideEnabled" is set to true, then the color temperature will go into effect even if "enabled == false"
    public static func setColorTemperature(_ value: Float, overrideEnabled: Bool = false) {
        let blueLightClient = CBBlueLightClient()
        
        // NOTE: "commit = true" saves the setting but only makes it effective if night shift is currently enabled (i.e. if "enabled == true"); this is useful if we are demonstrating what a color temperature effect would be to the user in a dialog
        // NOTE: "commit = false" saves the setting and makes it effective regardless of whether night shift is currently enabled
        let commit = !overrideEnabled
        blueLightClient.setStrength(value, commit: commit)
    }

    private static var notificationBlueLightClient: CBBlueLightClient? = nil
    private static var notificationCache_Enabled: Bool? = nil
    public static func enableStatusChangeNotifications() {
        if self.notificationBlueLightClient == nil {
            notificationBlueLightClient = CBBlueLightClient()
        }

        // capture cache values of all our Night Shift states/properties
        MorphicNightShift.notificationCache_Enabled = MorphicNightShift.getEnabled()
        
        self.notificationBlueLightClient?.setStatusNotificationBlock { pointerToStatus in
            guard let status = pointerToStatus?.pointee else {
                return
            }

            // if the enabled state has changed, notify our client of the change now
            if status.enabled.boolValue != MorphicNightShift.notificationCache_Enabled {
                MorphicNightShift.notificationCache_Enabled = status.enabled.boolValue
                NotificationCenter.default.post(name: .morphicFeatureNightShiftEnabledChanged, object: nil, userInfo: ["enabled" : status.enabled.boolValue])
            }
        }
    }
}

public extension NSNotification.Name {
    static let morphicFeatureNightShiftEnabledChanged = NSNotification.Name("org.raisingthefloor.morphicFeatureNightShiftEnabledChanged")
}
