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

public class MorphicLaunchDaemonsAndAgents {
    public struct MorphicLaunchDaemonOrAgentInfo {
        public let name: String
        public let serviceName: String

        public init(name: String, serviceName: String) {
            self.name = name
            self.serviceName = serviceName
        }
    }

    // list of launch (system) daemons and (user) agents
//    public static let controlStrip = MorphicLaunchDaemonOrAgentInfo(
//         name: "Control Strip",
//         serviceName: "com.apple.controlstrip"
//    )
//    //
    public static let dock = MorphicLaunchDaemonOrAgentInfo(
        name: "Dock",
        serviceName: "com.apple.Dock.agent"
    )
    //
    public static let finder = MorphicLaunchDaemonOrAgentInfo(
         name: "Finder",
         serviceName: "com.apple.Finder"
    )
    //
    public static let notificationCenter = MorphicLaunchDaemonOrAgentInfo(
         name: "Notification Center",
         serviceName: "com.apple.notificationcenterui.agent"
    )
    //
    public static let spotlight = MorphicLaunchDaemonOrAgentInfo(
         name: "Spotlight",
         serviceName: "com.apple.Spotlight"
    )
    //
    public static let systemUIServer = MorphicLaunchDaemonOrAgentInfo(
         name: "System UI Server",
         serviceName: "com.apple.SystemUIServer.agent"
    )
    //
    public static let textInputMenuBarExtra = MorphicLaunchDaemonOrAgentInfo(
         name: "Text Input Menubar Extra",
         serviceName: "com.apple.TextInputMenuAgent"
    )

    public static let allCases: [MorphicLaunchDaemonOrAgentInfo] = [
//        LaunchDaemonsAndAgents.controlStrip,
        MorphicLaunchDaemonsAndAgents.dock,
        MorphicLaunchDaemonsAndAgents.finder,
        MorphicLaunchDaemonsAndAgents.notificationCenter,
        MorphicLaunchDaemonsAndAgents.spotlight,
        MorphicLaunchDaemonsAndAgents.systemUIServer,
        MorphicLaunchDaemonsAndAgents.textInputMenuBarExtra
    ]

}
