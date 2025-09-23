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

internal class ConfigurableFeatures
{
    public enum AutorunConfigOption
    {
        case disabled
        case allLocalUsers
        case currentUser
    }

    public enum MorphicBarVisibilityAfterLoginOption {
        case show
        case hide
        case restore
    }

//    public var atOnDemandIsEnbled: Bool = true // NOTE: Windows-exclusive feature in current release
//    public var atUseCounterIsEnabled: Bool = false // NOTE: Windows-exclusive feature in current release
    public var autorunConfig: AutorunConfigOption? = nil
    public var checkForUpdatesIsEnabled: Bool = true
//    public var cloudSettingsTransferIsEnabled: Bool = true // NOTE: currently specified in Session instead of ConfigurableFeatures
    public var customMorphicBarsIsEnabled: Bool = true
    public var resetSettingsIsEnabled: Bool = false
    public var signInIsEnabled: Bool = true
    
    public var morphicBarVisibilityAfterLogin: MorphicBarVisibilityAfterLoginOption? = nil
    public var morphicBarExtraItems: [AppDelegate.MorphicBarExtraItem] = []

    //    public var hideMorphicAfterLoginUntil: Date? = nil // NOTE: Windows-exclusive feature in current release

    public var telemetryIsEnabled: Bool = true
    public var telemetrySiteId: String?
    
    static var shared: ConfigurableFeatures = {
        return ConfigurableFeatures()
    }()
}
