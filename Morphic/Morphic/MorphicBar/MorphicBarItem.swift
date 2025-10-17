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
import Cocoa
import MorphicCore
import MorphicMacOSNative
import MorphicSettings
import MorphicService
import MorphicUIAutomation
import OSLog

public class MorphicBarItem {
    
    var interoperable: [String: Interoperable?]
    
    public init(interoperable: [String: Interoperable?]) {
        self.interoperable = interoperable
    }
    
    func view() -> MorphicBarItemViewProtocol? {
        return nil
    }
    
    public static func items(from interoperables: [Interoperable?]) -> [MorphicBarItem] {
        var items = [MorphicBarItem]()
        for i in 0..<interoperables.count {
            if let dict = interoperables.dictionary(at: i) {
                if let item_ = item(from: dict) {
                    items.append(item_)
                }
            }
        }
        return items
    }

    internal static func items(from extraItems: [AppDelegate.MorphicBarExtraItem]) -> [MorphicBarItem] {
        var items = [MorphicBarItem]()
        for extraItem in extraItems {
            // convert our extra item into a dictionary
            var itemAsDictionary: [String: Interoperable?] = [:]
            itemAsDictionary["type"] = extraItem.type
            itemAsDictionary["label"] = extraItem.label
            itemAsDictionary["tooltipHeader"] = extraItem.tooltipHeader
            itemAsDictionary["tooltipText"] = extraItem.tooltipText
            // for type: link
            itemAsDictionary["url"] = extraItem.url
            // for type: action (from config.json file, not from custom bar web app schema)
            itemAsDictionary["function"] = extraItem.function
            // for type: control (from config.json file, not from custom bar web app schema)
            itemAsDictionary["feature"] = extraItem.feature
            // for type: application (from config.json file, not from custom bar web app schema)
            itemAsDictionary["appId"] = extraItem.appId

            if let item_ = item(from: itemAsDictionary) {
                items.append(item_)
            }
        }
        return items
    }

    public static func item(from interoperable: [String: Interoperable?]) -> MorphicBarItem? {
        switch interoperable.string(for: "type") {
        case "control":
            return MorphicBarControlItem(interoperable: interoperable)
        case "link":
            return MorphicBarLinkItem(interoperable: interoperable)
        case "application":
            let morphicBarApplicationItem = MorphicBarApplicationItem(interoperable: interoperable)
            // only show items with a supported 'default' (application category) or exeLaunchDetails
            if (morphicBarApplicationItem.default != nil) || (morphicBarApplicationItem.exeLaunchDetails != nil) {
                return morphicBarApplicationItem
            } else {
                return nil
            }
        case "action":
            if let _ = interoperable["function"] {
                // config.json (Windows-compatible) action item
                defer {
                    TelemetryClientProxy.enqueueActionMessage(eventName: "morphicBarExtraItem")
                }
                return MorphicBarActionItem(interoperable: interoperable)
            } else {
                // Morphic for macOS-style action (control) item
                return createMorphicBarActionControlItem(interoperable: interoperable)
            }
        default:
            return nil
        }
    }
    
    private static func createMorphicBarActionControlItem(interoperable: [String: Interoperable?]) -> MorphicBarItem? {
        // NOTE: argument 'label' should never be nil, but it was nil in all API call test results; as a practical matter this does not matter as we are not using the parameter in our implementation
                
        guard let identifier = interoperable["identifier"] as? String else {
            return nil
        }
                
        // map the custom action items to traditional control items (by mapping their interoperable data)
        
        var transformedInteroperable: [String: Interoperable?] = [:]
        
        transformedInteroperable["color"] = interoperable["color"] as? String

        switch identifier {
        case "color-vision":
            transformedInteroperable["feature"] = "colorvisiononoff"
        case "copy-paste":
            transformedInteroperable["feature"] = "copypaste"
        case "dark-mode":
            transformedInteroperable["feature"] = "darkmodeonoff"
        case "high-contrast":
            transformedInteroperable["feature"] = "contrast"
        case "log-off":
            transformedInteroperable["feature"] = "signout"
        case "magnify":
            transformedInteroperable["feature"] = "magnifieronoff"
        case "night-mode":
            transformedInteroperable["feature"] = "nightshift"
        case "read-aloud":
            transformedInteroperable["feature"] = "readselected"
        case "screen-zoom":
            transformedInteroperable["feature"] = "resolution"
        case "snip":
            transformedInteroperable["feature"] = "screensnip"
        case "volume":
            transformedInteroperable["feature"] = "volumewithoutmute"
        case "usbopeneject":
            transformedInteroperable["feature"] = "usbopeneject"
        default:
            // no other action items are supported
            break
        }
        
        // NOTE: for special features like signout, label and image are configurable
        transformedInteroperable["label"] = interoperable["label"] as? String
        transformedInteroperable["imageUrl"] = interoperable["imageUrl"] as? String

        let morphicBarControlItem = MorphicBarControlItem(interoperable: transformedInteroperable)
        morphicBarControlItem.style = .fixedWidth(segmentWidth: 49.25)
        
        return morphicBarControlItem
    }
}

class MorphicBarSeparatorItem: MorphicBarItem {
    override func view() -> MorphicBarItemViewProtocol? {
        let view = MorphicBarSeparatorItemView()
        view.target = self
        return view
    }
}

class MorphicBarLinkItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var imageUrl: String?
    var url: URL?
     
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        self.label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            self.color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            self.color = nil
        }
        //
        self.imageUrl = interoperable.string(for: "imageUrl")
        //
        // NOTE: argument 'url' should never be nil, but we use an empty string as a backup
        var url: URL?
        if let urlAsString = interoperable.string(for: "url") {
            // NOTE: if the url was malformed, that may result in a "nil" URL
            // SECURITY NOTE: we should strongly consider filtering urls by scheme (or otherwise) here
            url = URL(string: urlAsString)
        } else {
            url = nil
        }
        
        // validate the URL scheme
        switch url?.scheme?.lowercased() {
        case "http",
             "https":
            // valid
            break
        case "skype":
            // allowed for now, but in the future we may want to launch Skype directly and handle this information seperately
            break
        default:
            // disallowed/missing scheme: reject this URL
            url = nil
        }

        // capture the validated URL
        self.url = url
            
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }
        
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: icon, iconColor: nil)
        view.target = self
        view.action = #selector(MorphicBarLinkItem.openLink(_:))
        return view
    }
    
    @objc
    func openLink(_ sender: Any?) {
        if let url = self.url {
            NSWorkspace.shared.open(url)
        }
    }
}

enum MorphicBarActionItemFunction: String {
    case signOut
}
class MorphicBarActionItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var function: MorphicBarActionItemFunction?
     
    // NOTE: realistically these should be failable initializers (which can return nil)
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        // NOTE: argument 'function' should never be nil
        if let functionAsString = interoperable.string(for: "function") {
            function = MorphicBarActionItemFunction(rawValue: functionAsString)
        } else {
            function = nil
        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: nil, iconColor: nil)
        view.target = self
        view.action = #selector(MorphicBarActionItem.callFunction(_:))
        return view
    }
    
    @objc
    func callFunction(_ sender: Any?) {
        if let function = self.function {
            switch function {
            case .signOut:
                MorphicProcess.logOutUserViaOsaScriptWithConfirmation()
            }
        }
    }
}
enum MorphicBarApplicationDefaultOption: String {
    case browser
    case email
}
//
public enum ExecutableLaunchDetails {
    case bundleIdentifier(bundleIdentifier: String)
}
class MorphicBarApplicationItem: MorphicBarItem {
    var label: String
    var color: NSColor?
    var imageUrl: String?
    var `default`: MorphicBarApplicationDefaultOption?
    private var exe: String?
    var exeLaunchDetails: ExecutableLaunchDetails?

    override init(interoperable: [String : Interoperable?]) {
        // NOTE: argument 'label' should never be nil, but we use an empty string as a backup
        label = interoperable.string(for: "label") ?? ""
        //
        if let colorAsString = interoperable.string(for: "color") {
            color = NSColor.createFromRgbHexString(colorAsString)
        } else {
            color = nil
        }
        //
        imageUrl = interoperable.string(for: "imageUrl")
        //
        // NOTE: either argument "default" (application type) or "exe" should always be populated, but we assign a nil application and exe as a backup
        // NOTE: 'default' designates a category (e.g. "browser", "email") for which the OS lets the user select a default application
        if let `default` = interoperable.string(for: "default") {
            // NOTE: this function call will either return a known 'default' application option...or it will return nil (if the application isn't supported on macOS)
            self.default = MorphicBarApplicationDefaultOption(rawValue: `default`)
        } else {
            self.default = nil
        }
        //
        // NOTE: 'exe' designates the identifier of the EXE to run (e.g. "calendar", "calculator", "word", "adobeReader")
        // NOTE: 'appId' is the modern term for application identifier (and 'exe' is the old v1 API name...which we should discontinue use of as soon as practical)
        if let exe = interoperable.string(for: "exe") ?? interoperable.string(for: "appId") {
            self.exe = exe
            self.exeLaunchDetails = MorphicBarApplicationItem.convertExeIdentifierToExecutableLaunchDetails(exe: exe)
            
            // make sure that the application is installed; if it isn't, then clear out the exe info
            if case let .bundleIdentifier(bundleIdentifier) = self.exeLaunchDetails {
                let urlForApplication = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
                if (urlForApplication == nil) {
                    self.exe = nil
                    self.exeLaunchDetails = nil
                }
            }
        } else {
            self.exe = nil
        }
        
        super.init(interoperable: interoperable)
    }

    override func view() -> MorphicBarItemViewProtocol? {
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }
        
        let view = MorphicBarButtonItemView(label: label, labelColor: nil, fillColor: color, icon: icon, iconColor: nil)
        view.target = self
        // NOTE: generally, we should give preference to opening an executable directly ("exe") over opening the default application by type ("default")
        if self.exe != nil {
            view.action = #selector(MorphicBarApplicationItem.openExe(_:))
        } else {
            view.action = #selector(MorphicBarApplicationItem.openDefault(_:))
        }
        return view
    }
    
    @objc
    func openDefault(_ sender: Any?) {
        if let `default` = self.default {
            switch `default` {
            case .browser:
                // get the default browser (i.e. the default application used to open a default url)
                guard let applicationUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://www.example.com")!) else {
                    // FUTURE: return an error condition (i.e. could not find application)
                    return
                }
                self.openApplicationUrl(applicationUrl)
            case .email:
                NSWorkspace.shared.open(URL(string: "mailto:")!)
            }
        }
    }
    
    @objc
    func openExe(_ sender: Any?) {
        if let exeLaunchDetails = self.exeLaunchDetails {
            switch exeLaunchDetails {
            case .bundleIdentifier(let bundleIdentifier):
                guard let applicationUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                    // FUTURE: return an error condition (i.e. could not find application)
                    return
                }
                
                openApplicationUrl(applicationUrl)
            }
        }
    }
    
    private func openApplicationUrl(_ applicationUrl: URL) {
        let openConfiguration = NSWorkspace.OpenConfiguration()
        openConfiguration.activates = true
        NSWorkspace.shared.openApplication(at: applicationUrl, configuration: openConfiguration, completionHandler: { (application, error) in
            // FUTURE: return an error condition (presumably via callback) if this call results in an error
        })
    }

    private static func convertExeIdentifierToExecutableLaunchDetails(exe: String) -> ExecutableLaunchDetails? {
        switch exe {
        case "calculator":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.apple.calculator")
        case "firefox":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "org.mozilla.firefox")
        case "googleChrome":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.google.Chrome")
        case "microsoftEdge":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.edgemac")
        case "microsoftExcel":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.Excel")
        case "microsoftOneNote":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.onenote.mac")
        case "microsoftOutlook":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.Outlook")
        case "microsoftPowerPoint":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.Powerpoint")
        case "microsoftTeams":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.teams")
        case "microsoftWord":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.microsoft.Word")
        case "microsoftSkype":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.skype.skype")
        case "opera":
            return ExecutableLaunchDetails.bundleIdentifier(bundleIdentifier: "com.operasoftware.Opera")
        default:
            return nil
        }
    }
}

enum MorphicBarControlItemStyle {
    case autoWidth
    case fixedWidth(segmentWidth: CGFloat)
}
//
class MorphicBarControlItem: MorphicBarItem {
    
    enum Feature: String {
        case colorvisiononoff
        case contrast
        case contrastcolordarknight
        case copypaste
        case darkmodeonoff
        case magnifier
        case magnifieronoff
        case nightshift
        case reader
        case readselected
        case resolution
        case screensnip
        case signout
        case unknown
        case usbopeneject
        case volume
        case volumewithoutmute
        
        init(string: String?) {
            if let known = Feature(rawValue: string ?? "") {
                self = known
            } else {
                self = .unknown
            }
        }
    }

    // NOTE: these string should always be specified (in case the enum cases get renamed during refactoring) as they are used in URL paths
    enum ButtonCategory: String {
        case assistMac = "assist-mac"
        case colorvision = "colorvision"
        case contrast = "contrast"
        case copypaste = "copypaste"
        case darkmode = "darkmode"
        case logoff = "logoff"
        case magnifier = "magnifier"
        case nightmode = "nightmode"
        case readselMac = "readsel-mac"
        case snip = "snip"
        case textsize = "textsize"
        case usbdrives = "usbdrives"
        case volmute = "volmute"
    }
    
    static func learnMoreUrl(for buttonCategory: ButtonCategory) -> URL? {
        let learnMoreUrlPrefix = "https://morphic.org/rd/"
        let buttonCategoryTag = buttonCategory.rawValue
        return URL(string: learnMoreUrlPrefix + buttonCategoryTag)
    }
    
    static func quickDemoVideoUrl(for buttonCategory: ButtonCategory) -> URL? {
        let buttonCategoryUrlPrefix = "https://morphic.org/rd/"
        let buttonCategoryUrlSuffix = "-vid"
        let buttonCategoryTag = buttonCategory.rawValue
        return URL(string: buttonCategoryUrlPrefix + buttonCategoryTag + buttonCategoryUrlSuffix)
    }
    
    var feature: Feature
    var fillColor: NSColor? = nil 

    // NOTE: these values are for special buttons like "signoff" which have user-customizable labels and images
    var label: String
    var imageUrl: String?

    var style: MorphicBarControlItemStyle = .autoWidth
    
    override init(interoperable: [String : Interoperable?]) {
        // NOTE: for buttons with user-definable labels, argument 'label' should never be nil, but we use an empty string as a backup
        // NOTE: label is used for buttons like the "sign-off" button; for most other features this is not customizable
        self.label = interoperable.string(for: "label") ?? ""
        //
        self.feature = Feature(string: interoperable.string(for: "feature"))
        //
        if let colorAsString = interoperable.string(for: "color") {
            self.fillColor = NSColor.createFromRgbHexString(colorAsString)
        } else {
            self.fillColor = nil
        }
        //
        // NOTE: imageUrl is used for buttons like the "sign-off" button; for most other features this is not customizable
        self.imageUrl = interoperable.string(for: "imageUrl")

        super.init(interoperable: interoperable)
    }
    
    override func view() -> MorphicBarItemViewProtocol? {
        let buttonColor: NSColor = fillColor ?? .morphicPrimaryColor
        let alternateButtonColor: NSColor = fillColor ?? .morphicPrimaryColor
        // NOTE: to alternate the color of button segments, uncomment the following line instead
        //let alternateButtonColor: NSColor = fillColor ?? .morphicPrimaryColorLightend
        
        // NOTE: icons are only used on user-definable buttons which have imageUrl properties (like the "signout" button)
        var icon: MorphicBarButtonItemIcon? = nil
        if let imageUrl = self.imageUrl {
            icon = MorphicBarButtonItemIcon(rawValue: imageUrl)
        }

        switch feature {
        case .colorvisiononoff:
            let localized = LocalizedStrings(prefix: "control.feature.colorvision")
            let showHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            //
            let colorVisionOnSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "on"),
                fillColor: buttonColor,
                helpProvider: showHelpProvider,
                accessibilityLabel: localized.string(for: "on.help.title"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .colorvision),
                learnMoreTelemetryCategory: "colorFilter",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .colorvision),
                quickDemoVideoTelemetryCategory: "colorFilter",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityDisplayColorFilters, category: "colorFilter") },
                style: style
            )
            let colorVisionOffSemgent = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "off"),
                fillColor: alternateButtonColor,
                helpProvider: hideHelpProvider,
                accessibilityLabel: localized.string(for: "off.help.title"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .colorvision),
                learnMoreTelemetryCategory: "colorFilter",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .colorvision),
                quickDemoVideoTelemetryCategory: "colorFilter",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityDisplayColorFilters, category: "colorFilter") },
                style: style
            )
            let segments = [
                colorVisionOnSegment,
                colorVisionOffSemgent
            ]
            //
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.colorvision(_:))
            return view
        case .contrast:
            let localized = LocalizedStrings(prefix: "control.feature.contrast")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "on"),
                    fillColor: buttonColor,
                    helpProvider: onHelpProvider,
                    accessibilityLabel: localized.string(for: "on.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast),
                    learnMoreTelemetryCategory: "highContrast",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast),
                    quickDemoVideoTelemetryCategory: "highContrast",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityDisplayDisplay, category: "highContrast") },
                    style: style
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "off"),
                    fillColor: alternateButtonColor,
                    helpProvider: offHelpProvider,
                    accessibilityLabel: localized.string(for: "off.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast),
                    learnMoreTelemetryCategory: "highContrast",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast),
                    quickDemoVideoTelemetryCategory: "highContrast",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPane(.accessibilityDisplayDisplay)},
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrast(_:))
            return view
        case .contrastcolordarknight:
            let localized = LocalizedStrings(prefix: "control.feature.contrastcolordarknight")
            
            let contrastHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "contrast.help.title"), message: localized.string(for: "contrast.help.message")) }
            var contrastSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "contrast"),
                fillColor: buttonColor,
                helpProvider: contrastHelpProvider,
                accessibilityLabel: localized.string(for: "contrast.tts"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .contrast),
                learnMoreTelemetryCategory: "highContrast",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .contrast),
                quickDemoVideoTelemetryCategory: "highContrast",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityDisplayDisplay, category: "highContrast") },
                style: style
            )
            contrastSegment.getStateBlock = {
                return MorphicDisplayAccessibilitySettings.increaseContrastEnabled
            }
            contrastSegment.accessibilityLabelByState = [
                .on: localized.string(for: "contrast.tts.enabled"),
                .off: localized.string(for: "contrast.tts.disabled")
            ]
            //
            // enable contrast state change notifications
            AppDelegate.shared.enableContrastChangeNotifications()
            contrastSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureContrastEnabledChanged,
                stateKey: "enabled"
            )
            //
            let colorHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "color.help.title"), message: localized.string(for: "color.help.message")) }
            var colorSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "color"),
                fillColor: alternateButtonColor,
                helpProvider: colorHelpProvider,
                accessibilityLabel: localized.string(for: "color.tts"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .colorvision),
                learnMoreTelemetryCategory: "colorFilter",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .colorvision),
                quickDemoVideoTelemetryCategory: "colorFilter",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityDisplayColorFilters, category: "colorFilter") },
                style: style
            )
            colorSegment.getStateBlock = {
                return MorphicDisplayAccessibilitySettings.colorFiltersEnabled
            }
            colorSegment.accessibilityLabelByState = [
                .on: localized.string(for: "color.tts.enabled"),
                .off: localized.string(for: "color.tts.disabled")
            ]
            //
            // enable color filters enabled change notifications
            AppDelegate.shared.enableColorFiltersEnabledChangeNotifications()
            colorSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureColorFiltersEnabledChanged,
                stateKey: "enabled"
            )
            //
            let darkHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "dark.help.title"), message: localized.string(for: "dark.help.message")) }
            var darkSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "dark"),
                fillColor: buttonColor,
                helpProvider: darkHelpProvider,
                accessibilityLabel: localized.string(for: "dark.tts"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .darkmode),
                learnMoreTelemetryCategory: "darkMode",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .darkmode),
                quickDemoVideoTelemetryCategory: "darkMode",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.appearance, category: "darkMode") },
                style: style
            )
            darkSegment.getStateBlock = {
                let currentAppearanceTheme = MorphicDisplayAppearance.currentAppearanceTheme
                switch currentAppearanceTheme {
                case .dark:
                    return true
                case .light:
                    return false
                }
            }
            darkSegment.accessibilityLabelByState = [
                .on: localized.string(for: "dark.tts.enabled"),
                .off: localized.string(for: "dark.tts.disabled")
            ]
            //
            // enable dark mode (appearance) change notifications
            AppDelegate.shared.enableDarkAppearanceEnabledChangeNotifications()
            darkSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureInterfaceThemeChanged,
                stateKey: nil // NOTE: the button will query for the theme in real-time
            )
            //
            let nightHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "night.help.title"), message: localized.string(for: "night.help.message")) }
            var nightSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "night"),
                fillColor: alternateButtonColor,
                helpProvider: nightHelpProvider,
                accessibilityLabel: localized.string(for: "night.tts"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode),
                learnMoreTelemetryCategory: "nightMode",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode),
                quickDemoVideoTelemetryCategory: "nightMode",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.displaysNightShift, category: "nightMode") },
                style: style
            )
            nightSegment.getStateBlock = {
                return MorphicNightShift.getEnabled()
            }
            nightSegment.accessibilityLabelByState = [
                .on: localized.string(for: "night.tts.enabled"),
                .off: localized.string(for: "night.tts.disabled")
            ]
            //
            // enable night shift enabled change notifications
            MorphicNightShift.enableStatusChangeNotifications()
            nightSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                notificationName: NSNotification.Name.morphicFeatureNightShiftEnabledChanged,
                stateKey: "enabled"
            )
            //
            let segments = [
                contrastSegment,
                colorSegment,
                darkSegment,
                nightSegment
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.contrastcolordarknight(_:))
            return view
        case .copypaste:
            let localized = LocalizedStrings(prefix: "control.feature.copypaste")
            let copyHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            let pasteHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "paste.help.title"), message: localized.string(for: "paste.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "copy"),
                    fillColor: buttonColor,
                    helpProvider: copyHelpProvider,
                    accessibilityLabel: localized.string(for: "copy.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .copypaste),
                    learnMoreTelemetryCategory: "copyPaste",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .copypaste),
                    quickDemoVideoTelemetryCategory: "copyPaste",
                    settingsBlock: nil,
                    style: style),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "paste"),
                    fillColor: alternateButtonColor,
                    helpProvider: pasteHelpProvider,
                    accessibilityLabel: localized.string(for: "paste.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .copypaste),
                    learnMoreTelemetryCategory: "copyPaste",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .copypaste),
                    quickDemoVideoTelemetryCategory: "copyPaste",
                    settingsBlock: nil,
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.copyPaste(_:))
            return view
        case .darkmodeonoff:
            let localized = LocalizedStrings(prefix: "control.feature.darkmode")
            let showHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            //
            let darkModeOnSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "on"),
                fillColor: buttonColor,
                helpProvider: showHelpProvider,
                accessibilityLabel: localized.string(for: "on.help.title"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .darkmode),
                learnMoreTelemetryCategory: "darkMode",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .darkmode),
                quickDemoVideoTelemetryCategory: "darkMode",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.appearance, category: "darkMode") },
                style: style
            )
            let darkModeOffSemgent = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "off"),
                fillColor: alternateButtonColor,
                helpProvider: hideHelpProvider,
                accessibilityLabel: localized.string(for: "off.help.title"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .darkmode),
                learnMoreTelemetryCategory: "darkMode",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .darkmode),
                quickDemoVideoTelemetryCategory: "darkMode",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.appearance, category: "darkMode") },
                style: style
            )
            let segments = [
                darkModeOnSegment,
                darkModeOffSemgent
            ]
            //
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.darkmode(_:))
            return view
        case .magnifier,
             .magnifieronoff:
            // NOTE: magnifieronoff is identical to magnifier but shows "on/off" buttons instead of "show/hide" buttons
            let isOnOff = (feature == .magnifieronoff)
            //
            let localized = LocalizedStrings(prefix: "control.feature.magnifier")
            let showHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: isOnOff ? "on.help.title" : "show.help.title"), message: localized.string(for: isOnOff ? "on.help.message" : "show.help.message")) }
            let hideHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: isOnOff ? "off.help.title" : "hide.help.title"), message: localized.string(for: isOnOff ? "off.help.message" : "hide.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: isOnOff ? "on" : "show"),
                    fillColor: buttonColor, helpProvider: showHelpProvider,
                    accessibilityLabel: localized.string(for: isOnOff ? "on.help.title" : "show.tts"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .magnifier),
                    learnMoreTelemetryCategory: "magnifier",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .magnifier),
                    quickDemoVideoTelemetryCategory: "magnifier",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityZoom, category: "magnifier") },
                    style: style
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: isOnOff ? "off" : "hide"),
                    fillColor: alternateButtonColor,
                    helpProvider: hideHelpProvider,
                    accessibilityLabel: localized.string(for: isOnOff ? "off.help.title" : "hide.tts"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .magnifier),
                    learnMoreTelemetryCategory: "magnifier",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .magnifier),
                    quickDemoVideoTelemetryCategory: "magnifier",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilityZoom, category: "magnifier") },
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.magnifier(_:))
            return view
        case .nightshift:
            let localized = LocalizedStrings(prefix: "control.feature.nightshift")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "on"),
                    fillColor: buttonColor,
                    helpProvider: onHelpProvider,
                    accessibilityLabel: localized.string(for: "on.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode),
                    learnMoreTelemetryCategory: "nightMode",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode),
                    quickDemoVideoTelemetryCategory: "nightMode",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.displaysNightShift, category: "nightMode") },
                    style: style
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "off"),
                    fillColor: alternateButtonColor,
                    helpProvider: offHelpProvider,
                    accessibilityLabel: localized.string(for: "off.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .nightmode),
                    learnMoreTelemetryCategory: "nightMode",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .nightmode),
                    quickDemoVideoTelemetryCategory: "nightMode",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.displaysNightShift, category: "nightMode") },
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.nightShift(_:))
            return view
        case .reader:
            let localized = LocalizedStrings(prefix: "control.feature.reader")
            let onHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "on.help.title"), message: localized.string(for: "on.help.message")) }
            let offHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "off.help.title"), message: localized.string(for: "off.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "on"),
                    fillColor: buttonColor,
                    helpProvider: onHelpProvider,
                    accessibilityLabel: localized.string(for: "on.tts"),
                    learnMoreUrl: nil,
                    learnMoreTelemetryCategory: nil,
                    quickDemoVideoUrl: nil,
                    quickDemoVideoTelemetryCategory: nil,
                    settingsBlock: nil,
                    style: style
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "off"),
                    fillColor: alternateButtonColor,
                    helpProvider: offHelpProvider,
                    accessibilityLabel: localized.string(for: "off.tts"),
                    learnMoreUrl: nil,
                    learnMoreTelemetryCategory: nil,
                    quickDemoVideoUrl: nil,
                    quickDemoVideoTelemetryCategory: nil,
                    settingsBlock: nil,
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.reader(_:))
            return view
        case .readselected:
            let localized = LocalizedStrings(prefix: "control.feature.readselected")
            let playStopHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "playstop.help.title"), message: localized.string(for: "playstop.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "playstop"),
                    fillColor: buttonColor,
                    helpProvider: playStopHelpProvider,
                    accessibilityLabel: localized.string(for: "playstop.tts"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .readselMac),
                    learnMoreTelemetryCategory: "readAloud",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .readselMac),
                    quickDemoVideoTelemetryCategory: "readAloud",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.accessibilitySpeech, category: "readAloud") },
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.readselected)
            return view
        case .resolution:
            let localized = LocalizedStrings(prefix: "control.feature.resolution")
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "bigger"),
                    fillColor: buttonColor,
                    helpProvider:  QuickHelpTextSizeBiggerProvider(/*display: Display.main, */localized: localized),
                    accessibilityLabel: localized.string(for: "bigger.tts"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .textsize),
                    learnMoreTelemetryCategory: "textSize",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .textsize),
                    quickDemoVideoTelemetryCategory: "textSize",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.displaysDisplay, category: "textSize") },
                    style: .fixedWidth(segmentWidth: 31)
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "smaller"),
                    fillColor: alternateButtonColor,
                    helpProvider: QuickHelpTextSizeSmallerProvider(/*display: Display.main, */localized: localized),
                    accessibilityLabel: localized.string(for: "smaller.tts"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .textsize),
                    learnMoreTelemetryCategory: "textSize",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .textsize),
                    quickDemoVideoTelemetryCategory: "textSize",
                    settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.displaysDisplay, category: "textSize") },
                    style: .fixedWidth(segmentWidth: 31)
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.zoom(_:))
            return view
        case .signout:
            let view = MorphicBarButtonItemView(label: self.label, labelColor: nil, fillColor: self.fillColor, icon: icon, iconColor: nil)
            view.target = self
            view.action = #selector(MorphicBarControlItem.signout(_:))
            return view
        case .screensnip:
            let localized = LocalizedStrings(prefix: "control.feature.screensnip")
            let copyHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "copy.help.title"), message: localized.string(for: "copy.help.message")) }
            var snipSegment = MorphicBarSegmentedButton.Segment(
                title: localized.string(for: "copy"),
                fillColor: buttonColor,
                helpProvider: copyHelpProvider,
                accessibilityLabel: localized.string(for: "copy.tts"),
                learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .snip),
                learnMoreTelemetryCategory: "screenSnip",
                quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .snip),
                quickDemoVideoTelemetryCategory: "screenSnip",
                settingsBlock: { try await SettingsLinkActions.openSystemSettingsPaneWithTelemetry(.keyboardShortcutsScreenshots, category: "screenSnip") },
                style: style
            )
            snipSegment.settingsMenuItemTitle = "Other Screenshot Shortcuts"
            let segments = [
                snipSegment
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.screensnip)
            return view
        case .usbopeneject:
            let localized = LocalizedStrings(prefix: "control.feature.usbdrives")
            let openHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "open.help.title"), message: localized.string(for: "open.help.message")) }
            let ejectHelpProvider = QuickHelpDynamicTextProvider { (title: localized.string(for: "eject.help.title"), message: localized.string(for: "eject.help.message")) }
            let segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "open"),
                    fillColor: buttonColor,
                    helpProvider: openHelpProvider,
                    accessibilityLabel: localized.string(for: "open.help.title"),
                    learnMoreUrl: nil,
                    learnMoreTelemetryCategory: nil,
                    quickDemoVideoUrl: nil,
                    quickDemoVideoTelemetryCategory: nil,
                    settingsBlock: nil,
                    style: style
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "eject"),
                    fillColor: alternateButtonColor,
                    helpProvider: ejectHelpProvider,
                    accessibilityLabel: localized.string(for: "eject.help.title"),
                    learnMoreUrl: nil,
                    learnMoreTelemetryCategory: nil,
                    quickDemoVideoUrl: nil,
                    quickDemoVideoTelemetryCategory: nil,
                    settingsBlock: nil,
                    style: style
                )
            ]
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.contentInsets = NSEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.usbdrives(_:))
            return view
        case .volume,
             .volumewithoutmute:
            let localized = LocalizedStrings(prefix: "control.feature.volume")
            var segments = [
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "up"),
                    fillColor: buttonColor,
                    helpProvider: QuickHelpVolumeUpProvider(audioOutput: AudioOutput.main, localized: localized),
                    accessibilityLabel: localized.string(for: "up.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute),
                    learnMoreTelemetryCategory: "volume",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute),
                    quickDemoVideoTelemetryCategory: "volume",
                    settingsBlock: nil,
                    style: .fixedWidth(segmentWidth: 31)
                ),
                MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "down"),
                    fillColor: alternateButtonColor,
                    helpProvider: QuickHelpVolumeDownProvider(audioOutput: AudioOutput.main, localized: localized),
                    accessibilityLabel: localized.string(for: "down.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute),
                    learnMoreTelemetryCategory: "volume",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute),
                    quickDemoVideoTelemetryCategory: "volume",
                    settingsBlock: nil,
                    style: .fixedWidth(segmentWidth: 31)
                )
            ]
            if feature == .volume {
                // create and add mute segment
                var muteSegment = MorphicBarSegmentedButton.Segment(
                    title: localized.string(for: "mute"),
                    fillColor: buttonColor,
                    helpProvider: QuickHelpVolumeMuteProvider(audioOutput: AudioOutput.main, localized: localized),
                    accessibilityLabel: localized.string(for: "mute.help.title"),
                    learnMoreUrl: MorphicBarControlItem.learnMoreUrl(for: .volmute),
                    learnMoreTelemetryCategory: "volume",
                    quickDemoVideoUrl: MorphicBarControlItem.quickDemoVideoUrl(for: .volmute),
                    quickDemoVideoTelemetryCategory: "volume",
                    settingsBlock: nil,
                    style: style
                )
                muteSegment.getStateBlock = {
                    guard let defaultAudioDeviceId = MorphicAudio.getDefaultAudioDeviceId() else {
                        // default: return false
                        return false
                    }
                    guard let muteState = MorphicAudio.getMuteState(for: defaultAudioDeviceId) else {
                        // default: return false
                        return false
                    }
                    return muteState
                }
                muteSegment.stateUpdatedNotification = MorphicBarSegmentedButton.Segment.StateUpdateNotificationInfo(
                    notificationName: NSNotification.Name.morphicAudioMuteStateChanged,
                    stateKey: "muteState"
                )
                muteSegment.accessibilityLabelByState = [
                    .on: localized.string(for: "mute.tts.muted"),
                    .off: localized.string(for: "mute.tts.unmuted")
                ]
                //
                // enable muteState change notifications
                if let defaultAudioDeviceId = MorphicAudio.getDefaultAudioDeviceId() {
                    do {
                        try MorphicAudio.enableMuteStateChangeNotifications(for: defaultAudioDeviceId)
                    } catch {
                        NSLog("Could not subscribe to mute state change notifications")
                    }
                }
                //
                segments.append(
                    muteSegment
                )
            }
            let view = MorphicBarSegmentedButtonItemView(title: localized.string(for: "title"), segments: segments, style: style)
            view.segmentedButton.target = self
            view.segmentedButton.action = #selector(MorphicBarControlItem.volume(_:))
            return view
        default:
            return nil
        }
    }
    
    @objc
    func zoom(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        
        // NOTE: due to a limitation in Morphic 1.x, we use the current mouse pointer location as a proxy for the screen on which the
        //       Morphic bar is currently shown; in the future, we should get the current display for the MorphicBar WINDOW instead
        guard let mousePointerLocation = MorphicSettings.MorphicMouse.getCurrentLocation() else {
            assertionFailure("Could not locate the mouse pointer")
            return
        }
        guard let display = Display.displayContainingPoint(mousePointerLocation) else {
            assertionFailure("Could not determine which display contains the mouse pointer")
            return
        }

        var percentage: Double
        var isZoomingIn: Bool
        var zoomToStep: Int?
        let currentStepOffsetFromNormalMode = display.currentStepOffsetFromNormalMode
        //
        // to handle special zoom resolutions which could be beyond our range, capture the current percentage and make sure we actually go up/down in zoom percentage
        let currentPercentage = display.currentPercentage
        var canZoom = currentStepOffsetFromNormalMode != nil // if we have a current offset, we can zoom (there and back)
        //
        if segment == 0 {
            percentage = display.percentage(zoomingIn: 1)
            zoomToStep = currentStepOffsetFromNormalMode != nil ? currentStepOffsetFromNormalMode! + 1 : nil
            isZoomingIn = true
            // if we were able to find a greater percentage than the current percentage, we can zoom (i.e. override 'canZoom')
            if (/* canZoom == false && */currentPercentage < percentage) {
                canZoom = true
            }
        } else {
            percentage = display.percentage(zoomingOut: 1)
            zoomToStep = currentStepOffsetFromNormalMode != nil ? currentStepOffsetFromNormalMode! - 1 : nil
            isZoomingIn = false
            // if we were able to find a lesser percentage than the current percentage, we can zoom (i.e. override 'canZoom')
            if (/* canZoom == false && */currentPercentage > percentage) {
                canZoom = true
            }
        }
        //
        defer {
            // NOTE: if we wanted to send the scale percentage, we could capture "scalePercentage"--and then send that as a parameter via eventData; ideally we'd look at this from a "relative to system default/recommended %" basis, rather than "dots" or absolute %
            if isZoomingIn == true {
                TelemetryClientProxy.enqueueActionMessage(eventName: "textSizeIncrease")
            } else {
                TelemetryClientProxy.enqueueActionMessage(eventName: "textSizeDecrease")
            }
        }
        //
        if (canZoom == true) {
            _ = try? display.zoom(to: percentage)
        } else {
            // TODO: alert the user that we cannot zoom
        }
    }
    
    @objc
    func volume(_ sender: Any?) {
        guard let senderAsSegmentedButton = sender as? MorphicBarSegmentedButton else {
            return
        }
        let segment = senderAsSegmentedButton.selectedSegmentIndex
        guard let output = AudioOutput.main else {
            return
        }
        if segment == 0 {
            if output.isMuted {
                _ = try? output.setMuted(false)
            } else {
                _ = try? output.setVolume(output.volume + 0.05)
            }
        } else if segment == 1 {
            if output.isMuted {
                _ = try? output.setMuted(false)
            } else {
                _ = try? output.setVolume(output.volume - 0.05)
            }
        } else if segment == 2 {
            let currentMuteState = output.isMuted
            let newMuteState = !currentMuteState
            _ = try? output.setMuted(newMuteState)
        }

        // update the state of the mute button
        senderAsSegmentedButton.setButtonState(index: 2, stateAsBool: output.isMuted)
    }

    @objc
    func volumeWithoutMute(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        guard let output = AudioOutput.main else {
            return
        }
        if segment == 0 {
            if output.isMuted {
                _ = try? output.setMuted(false)
            } else {
                _ = try? output.setVolume(output.volume + 0.05)
            }
        } else if segment == 1 {
            if output.isMuted {
                _ = try? output.setMuted(false)
            } else {
                _ = try? output.setVolume(output.volume - 0.05)
            }
        }
    }

    @objc
    func copyPaste(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }

        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }

        let keyCode: CGKeyCode
        if segment == 0 {
            // copy
            keyCode = CGKeyCode(kVK_ANSI_C)
        } else if segment == 1 {
            // paste
            keyCode = CGKeyCode(kVK_ANSI_V)
        } else {
            // invalid segment
            return
        }
        let keyOptions = MorphicInput.KeyOptions.withCommandKey
        
        // get the window ID of the topmost window
        guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
            NSLog("Could not get ID of topmost window")
            return
        }

        // capture a reference to the topmost application
        guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
            NSLog("Could not get reference to application owning the topmost window")
            return
        }

        // activate the topmost application
        guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
            NSLog("Could not activate the topmost window")
            return
        }

        AsyncUtils.wait(atMost: 2.0, for: { topmostApplication.isActive == true }) {
            success in
            if success == false {
                NSLog("Could not activate topmost application within two seconds")
            }
            
            // send the appropriate hotkey to the system
            guard let _ = try? MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) else {
                NSLog("Could not send copy/paste hotkey to the keyboard input stream")
                return
            }
        }
    }

    @objc
    func signout(_ sender: Any?) {
        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: "signOut")
        }
        
        MorphicProcess.logOutUserViaOsaScriptWithConfirmation()
    }
    
    @objc
    func screensnip(_ sender: Any?) {
        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: "screenSnip")
        }

        // verify that we have accessibility permissions (since UI automation and sendKeys will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            return
        }

        var keyCode: CGKeyCode
        var keyOptions: MorphicInput.KeyOptions
        var hotKeyEnabled: Bool
        //
        if let hotKeyInfo = MorphicInput.hotKeyForSystemKeyboardShortcut(.copyPictureOfSelectedAreaToTheClipboard) {
            keyCode = hotKeyInfo.keyCode
            keyOptions = hotKeyInfo.keyOptions
            hotKeyEnabled = hotKeyInfo.enabled
        } else {
            // NOTE: in macOS 10.15+ (tested through 10.15), the hotkeys are not written out to the appropriate .plist file until one of them is changed (including disabling the enabled-by-default feature); the current strategy is to assume the default key combo in this scenario, but in the future we may want to consider reverse engineering the HI libraries or Keyboard system preferences pane to find another way to get this data
            
            // default values
            keyCode = CGKeyCode(kVK_ANSI_4)
            keyOptions = [
                .withShiftKey,
                .withControlKey,
                .withCommandKey
            ]
            hotKeyEnabled = true
        }
        
        guard hotKeyEnabled == true else {
            NSLog("Screen snip feature is currently disabled")
            return
        }
        
        // hide the QuickHelp window
        QuickHelpWindow.hide(withoutDelay: true) {
            // after we hide the QuickHelp window, send our key
            
            guard let _ = try? MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) else {
                NSLog("Could not send 'screen snip' hotkey to the keyboard input stream")
                return
            }
        }
    }

    // NOTE: the operation of the button's "setColorFilterState" is a more complicated script than what the settings handler for color filter state does (i.e. that setting handler opens the System Settings and checks/unchecks the appropriate box)
    private func setColorFilterState(_ state: Bool, waitAtMost: TimeInterval) async throws {
        // if the inverse state is "enabled", then make sure we've set the initial color filter type
        if state == true {
            // set the default color filter type (if it hasn't already been set)
            let didSetInitialColorFilterType = Session.shared.bool(for: .morphicDidSetInitialColorFilterType) ?? false
            if didSetInitialColorFilterType == false {
                // NOTE: we currently ignore success/failure from the following function
                let _ = try await AppDelegate.shared.setInitialColorFilterType(waitAtMost: waitAtMost)
            }
        }
        
        // apply the inverse state
        //
        // NOTE: due to current limitations in our implementation, we are unable to disable "invert colors" (which is the desired effect when enabling color filters); this is unlikely to be a common scenario, but if we run into it then we need to use the backup UI automation mechanism
        // NOTE: in the future, we should rework the settings handlers so that they can call native code which can launch a UI automation (instead of being either/or)...and then move this logic to the settings handler code
        if state == true && MorphicDisplayAccessibilitySettings.invertColorsEnabled == true {
            // NOTE: in our current implementation, we have no method to determine success/failure of the operation
            Session.shared.apply(state, for: .macosColorFilterEnabled, completion: { _ in })
        } else {
            // NOTE: in our current implementation, we have no method to determine success/failure of the operation
            MorphicDisplayAccessibilitySettings.setColorFiltersEnabled(state)
        }
    }
    
    @objc
    func colorvision(_ sender: Any?) {
        guard let senderAsSegmentedButton = sender as? MorphicBarSegmentedButton else {
            return
        }
        let segment = senderAsSegmentedButton.selectedSegmentIndex
        
        let newValue = (segment == 0 ? true : false)
        
        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: (newValue == true) ? "colorFiltersOn" : "colorFiltersOff")
        }

        Task {
            let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
            try await self.setColorFilterState(newValue, waitAtMost: waitForTimespan)

            guard let verifyColorFiltersAreEnabled = try AccessibilityDisplaySettings.getColorFiltersAreEnabled() else {
                // could not get current setting
                return
            }
            await senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyColorFiltersAreEnabled)
        }
    }
    
    // NOTE: this function returns the new contrast state
    func toggleContrastState(waitAtMost: TimeInterval) async throws -> Bool {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            throw MorphicError.unspecified
        }
        
        // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
        let uiAutomationSequence = UIAutomationSequence()
        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

        // capture the current "contrast enabled" setting
        var waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let increaseContrastIsEnabled = try await AccessibilityDisplayUIAutomationScript.getIncreaseContrastIsOn(sequence: uiAutomationSequence, waitAtMost: waitForTimespan)
        // calculate the inverse state
        let newIncreaseContrastEnabled = !increaseContrastIsEnabled
    
        waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        try await self.setContrastState(newIncreaseContrastEnabled, waitAtMost: waitForTimespan)

        // verify that the state has changed
        waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
        let verifyIncreaseContrastEnabled = try await AsyncUtils.wait(atMost: waitForTimespan) {
            guard let verifyValue = try MorphicSettings.AccessibilityDisplaySettings.getIncreaseContrastIsEnabled() else {
                return false
            }

            return verifyValue == newIncreaseContrastEnabled
        }
        if verifyIncreaseContrastEnabled == false {
            // could not verify "reduce transparency" value change
            throw MorphicError.unspecified
        }

        return newIncreaseContrastEnabled
    }
    
    func setContrastState(_ value: Bool, waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            throw MorphicError.unspecified
        }

        // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
        let sequence = UIAutomationSequence()

//        let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost
    
        let setSettingProxy = IncreaseConstrastUIAutomationSetSettingProxy()
        try await setSettingProxy.setIncreaseContrast(value, sequence: sequence, waitAtMost: waitAtMost)
    }
    
    @objc
    func contrast(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        
        let newState: Bool
        if segment == 0 {
            newState = true
        } else {
            newState = false
        }
        
        Task {
            // NOTE: we have no mechanism to report success/failure in the current implementation of this "contrast(...)" @objc function
            do {
                let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                try await self.setContrastState(newState, waitAtMost: waitForTimespan)
            } catch {
                // NOTE: we don't currently have a way to report an error to the caller
            }
        }
    }
    
    @objc
    func usbdrives(_ sender: Any?) {
        guard let usbDriveMountingPaths = try? MorphicDisk.getAllUsbDriveMountPaths() else {
            // TODO: once Morphic can catch and display errors, handle this error
            // "Could not retrieve a list of all USB drive mount paths"
            return
        }
        
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            // open all USB drives
            
            // open directory paths using Finder
            for path in usbDriveMountingPaths {
                _ = try? MorphicDisk.openDirectory(path: path)
            }
        } else {
            // safely eject all USB drives
            let numberOfDisks = usbDriveMountingPaths.count
            var numberOfDiskEjectsAttempted = 0
            var failedMountPaths: [String] = []
            
            // unmount and eject disk using disk arbitration
            for mountPath in usbDriveMountingPaths {
                do {
                    try MorphicDisk.ejectDisk(mountPath: mountPath) {
                        ejectedDiskPath, success in
                        //
                        numberOfDiskEjectsAttempted += 1
                        //
                        if success == true {
                            // we have ejected the disk at mount path: 'ejectedDiskPath'
                        } else {
                            // we failed to eject the disk at mount path: 'ejectedDiskPath'
                            failedMountPaths.append(mountPath)
                        }
                        
                        if numberOfDiskEjectsAttempted == numberOfDisks {
                            // if a callback was provided, call it with success/failure (and an array of all mounting paths which failed)
                            if failedMountPaths.count == 0 {
                                // TODO: in the future, consider offering a callback (or an async wait of some sort) to get confirmation once the operation has completed
//                                callback?.call(args: [true, Array<String>?(nil)])
                                return
                            } else {
                                // TODO: in the future, consider offering a callback (or an async wait of some sort) to get confirmation once the operation has completed
//                                callback?.call(args: [false, failedMountPaths])
                                return
                            }
                        }
                    }
                } catch MorphicDisk.EjectDiskError.volumeNotFound {
                    // TODO: once Morphic can catch and display errors, handle this error
                    // "Failed to eject the disk at mount path: \(mountPath); volume was not found"
                } catch MorphicDisk.EjectDiskError.otherError {
                    // TODO: once Morphic can catch and display errors, handle this error
                    // "Failed to eject the disk at mount path: \(mountPath); misc. error encountered"
                } catch _ {
                    // TODO: there should not be any other error conditions, but the compiler is warning that this switch is not exhaustive; once we have a way to catch and display errors we should determine which error is not being caught and handle it--or log and fatalError() here if this is an impossible code path
                }
            }
        }
    }
    
    @objc
    func contrastcolordarknight(_ sender: Any?) {
        guard let senderAsSegmentedButton = sender as? MorphicBarSegmentedButton else {
            return
        }
        let segment = senderAsSegmentedButton.selectedSegmentIndex
        switch segment {
        case 0:
            // contrast (increase contrast enabled)
            Task {
                do {
                    // NOTE: due to limitations in how this function gets called after the button press, we don't have a good way to return the result of the toggle (i.e. the new state)
                    let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                    let newContrastState = try await self.toggleContrastState(waitAtMost: waitForTimespan)

                    defer {
                        TelemetryClientProxy.enqueueActionMessage(eventName: newContrastState ? "highContrastOn" : "highContrastOff")
                    }
                    await senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: newContrastState)
                } catch {
                    // ignore any errors; we don't have a way to report success/failure
                }
            }
        case 1:
            // color (color filter)
            
            // capture the current "color filter enabled" setting
            SettingsManager.shared.capture(valueFor: .macosColorFilterEnabled) {
                value in
                guard let valueAsBoolean = value as? Bool else {
                    // could not get current setting
                    return
                }
                // calculate the inverse state
                let newValue = !valueAsBoolean
                
                defer {
                    TelemetryClientProxy.enqueueActionMessage(eventName: newValue ? "colorFiltersOn" : "colorFiltersOff")
                }
                
                Task {
                    let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                    try await self.setColorFilterState(newValue, waitAtMost: waitForTimespan)

                    guard let verifyColorFiltersAreEnabled = try AccessibilityDisplaySettings.getColorFiltersAreEnabled() else {
                        // could not get current setting
                        return
                    }
                    await senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyColorFiltersAreEnabled)
                }
            }
        case 2:
            // dark
            
            // NOTE: unlike System Preferences, we do not copy the current screen and then "fade" it into the new theme once the theme has switched; if we need that kind of behavior then we'll need screen capture permissions or we'll need to use the alternate (UI automation) code below.  There may also be other alternatives.
            let newDarkModeEnabled: Bool
            switch MorphicDisplayAppearance.currentAppearanceTheme {
            case .dark:
                newDarkModeEnabled = false
            case .light:
                newDarkModeEnabled = true
            }
            //
            defer {
                TelemetryClientProxy.enqueueActionMessage(eventName: newDarkModeEnabled ? "darkModeOn" : "darkModeOff")
            }
            //
            switch newDarkModeEnabled {
            case true:
                MorphicDisplayAppearance.setCurrentAppearanceTheme(.dark)
            case false:
                MorphicDisplayAppearance.setCurrentAppearanceTheme(.light)
            }
            //
            let verifyCurrentAppearanceTheme = MorphicDisplayAppearance.currentAppearanceTheme
            let verifyButtonState: Bool
            switch verifyCurrentAppearanceTheme {
            case .dark:
                verifyButtonState = false
            case .light:
                verifyButtonState = true
            }
            senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyButtonState)

//            // NOTE: if we ever have problems with our reverse-engineered implementation (above), the below UI automation code also works (albeit very slowly); note that this only works with macOS releases prior to macOS 13.0 and it would need to be updated to the correspondingly-appropriate code for newer versions of macOS
//            switch NSApp.effectiveAppearance.name {
//            case .darkAqua,
//                 .vibrantDark,
//                 .accessibilityHighContrastDarkAqua,
//                 .accessibilityHighContrastVibrantDark:
//                let lightAppearanceCheckboxUIAutomation = LightAppearanceUIAutomation()
//                lightAppearanceCheckboxUIAutomation.apply(true) {
//                    success in
//                    // we do not currently have a mechanism to report success/failure
//                    senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: newValue)
//                }
//            case .aqua,
//                 .vibrantLight,
//                 .accessibilityHighContrastAqua,
//                 .accessibilityHighContrastVibrantLight:
//                let darkAppearanceCheckboxUIAutomation = DarkAppearanceUIAutomation()
//                darkAppearanceCheckboxUIAutomation.apply(true) {
//                    success in
//                    // we do not currently have a mechanism to report success/failure
//                    senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: newValue)
//                }
//            default:
//                // unknown appearance
//                break
//            }
        case 3:
            // night
            
            let nightShiftEnabled = MorphicNightShift.getEnabled()
            let newNightShiftEnabled = !nightShiftEnabled
            //
            defer {
                TelemetryClientProxy.enqueueActionMessage(eventName: newNightShiftEnabled ? "nightModeOn" : "nightModeOff")
            }
            //
            MorphicNightShift.setEnabled(newNightShiftEnabled)
            //
            let verifyNightShiftEnabled = MorphicNightShift.getEnabled()
            senderAsSegmentedButton.setButtonState(index: segment, stateAsBool: verifyNightShiftEnabled)
        default:
            fatalError("impossible code branch")
        }
    }
    
    private func setDarkModeState(_ state: Bool, completion: @escaping (Bool) -> Void) {
        
    }
    
    @objc
    func darkmode(_ sender: Any?) {
        // NOTE: if we ever have problems with our reverse-engineered implementation, see the slow automation code in function "contrastcolordarknight"'s dark mode code
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            defer {
                TelemetryClientProxy.enqueueActionMessage(eventName: "darkModeOn")
            }

            MorphicDisplayAppearance.setCurrentAppearanceTheme(.dark)
        } else {
            defer {
                TelemetryClientProxy.enqueueActionMessage(eventName: "darkModeOff")
            }

            MorphicDisplayAppearance.setCurrentAppearanceTheme(.light)
        }
    }
    
    @objc
    func nightShift(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            MorphicNightShift.setEnabled(true)
        } else {
            MorphicNightShift.setEnabled(false)
        }
    }

    @objc
    func reader(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        if segment == 0 {
            Session.shared.apply(true, for: .macosVoiceOverEnabled) {
                _ in
            }
        } else {
            Session.shared.apply(false, for: .macosVoiceOverEnabled) {
                _ in
            }
        }
    }

    @objc
    func readselected(_ sender: Any?) {
        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: "readSelectedToggle")
        }
        
        Task {
            do {
                let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                try await self.readSelectedText(waitAtMost: waitForTimespan)
            } catch {
                // NOTE: we currently have no method for alerting the user to errors
            }
        }
    }

    //
    
    // NOTE: sendSpeakSelectedTextHotKey will be called synchronously or asynchronously (depending on whether we need to enable the OS feature asynchronously first)
    private static func sendSpeakSelectedTextHotKey(defaults: UserDefaults) {
        // obtain any custom-specified key sequence used for activating the "speak selected text" feature in macOS (or else assume default)
        let speakSelectedTextHotKeyCombo = defaults.integer(forKey: "SpokenUIUseSpeakingHotKeyCombo")
        //
        let keyCode: CGKeyCode
        let keyOptions: MorphicInput.KeyOptions
        if speakSelectedTextHotKeyCombo != 0 {
            guard let (customKeyCode, customKeyOptions) = MorphicInput.parseDefaultsKeyCombo(speakSelectedTextHotKeyCombo) else {
                // NOTE: while we should be able to decode any custom hotkey, this code is here to capture edge cases we have not anticipated
                // NOTE: in the future, we should consider an informational prompt alerting the user that we could not decode their custom hotkey (so they know why the feature did not work...or at least that it intentionally did not work)
                NSLog("Could not decode custom hotkey")
                return
            }
            keyCode = customKeyCode
            keyOptions = customKeyOptions
        } else {
            // default hotkey is Option+Esc
            keyCode = CGKeyCode(kVK_Escape)
            keyOptions = .withAlternateKey
        }
        
        //
        
        // get the window ID of the topmost window
        guard let (_ /* topmostWindowOwnerName */, topmostProcessId) = MorphicWindow.getWindowOwnerNameAndProcessIdOfTopmostWindow() else {
            NSLog("Could not get ID of topmost window")
            return
        }

        // capture a reference to the topmost application
        guard let topmostApplication = NSRunningApplication(processIdentifier: pid_t(topmostProcessId)) else {
            NSLog("Could not get reference to application owning the topmost window")
            return
        }
        
        // activate the topmost application
        guard topmostApplication.activate(options: .activateIgnoringOtherApps) == true else {
            NSLog("Could not activate the topmost window")
            return
        }
        
        AsyncUtils.wait(atMost: 2.0, for: { topmostApplication.isActive == true }) {
            success in
            
            if success == false {
                NSLog("Could not activate topmost application within two seconds")
            }
            
            // send the "speak selected text key" to the system
            guard let _ = try? MorphicInput.sendKey(keyCode: keyCode, keyOptions: keyOptions) else {
                NSLog("Could not send 'Speak selected text' hotkey to the keyboard input stream")
                return
            }
        }
    }
    
    func readSelectedText(waitAtMost: TimeInterval) async throws {
        // verify that we have accessibility permissions (since UI automation will not work without them)
        // NOTE: this function call will prompt the user for authorization if they have not already granted it
        guard MorphicA11yAuthorization.authorizationStatus(promptIfNotAuthorized: true) == true else {
            NSLog("User had not granted 'accessibility' authorization; user now prompted")
            throw MorphicError.unspecified
        }

        // NOTE: we retrieve system settings here which are _not_ otherwise captured by Morphic; if we decide to capture those settings in the future for broader capture/apply purposes, then we should modify this code to access those settings via Session.shared (if doing so will ensure that we are not getting cached data...rather than 'captured or set data'...since we need to check these settings every time this function is called).
        let defaultsDomain = "com.apple.speech.synthesis.general.prefs"
        guard let defaults = UserDefaults(suiteName: defaultsDomain) else {
            NSLog("Could not access defaults domain: \(defaultsDomain)")
            return
        }
        
        // make sure the user has "speak selected text..." enabled in System Preferences
        let speakSelectedTextKeyEnabled = defaults.bool(forKey: "SpokenUIUseSpeakingHotKeyFlag")
        if speakSelectedTextKeyEnabled == false {
            // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
            let uiAutomationSequence = UIAutomationSequence()
            let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

            do {
                let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                try await AccessibilitySpokenContentUIAutomationScript.setSpeakSelectionIsEnabled(true, sequence: uiAutomationSequence, waitAtMost: waitForTimespan)

                // send the hotkey (asynchronously) once we have enabled macOS's "speak selected text" feature
                // NOTE: although the setting has been updated (and reading the default will now return true), it takes macOS a few seconds to recognize the new hotkey.  We have not found any reliable way to detect when macOS recognizes the new hotkey combo, so we fall back to the (not ideal) strategy of simply waiting an arbitrary two seconds.
                AsyncUtils.wait(atMost: 2.0, for: { false /* return false means to wait the full interval */ }) {
                    success in
                    Self.sendSpeakSelectedTextHotKey(defaults: defaults)
                }
            } catch {
                // ignore any errors, as we don't have any mechanism to report errors
            }
        } else {
            // send the hotkey (synchronously) now
            Self.sendSpeakSelectedTextHotKey(defaults: defaults)
        }
    }

    @objc
    func magnifier(_ sender: Any?) {
        guard let segment = (sender as? MorphicBarSegmentedButton)?.selectedSegmentIndex else {
            return
        }
        let session = Session.shared

        let newState: Bool = (segment == 0 ? true : false)

        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: (newState == true) ? "magnifierShow" : "magnifierHide")
        }
        
        Task {
            do {
                let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                try await self.setMagnifierState(newState, waitAtMost: waitForTimespan)
            } catch {
                // NOTE: we don't currently have a mechanism to raise errors to the user
            }
        }
    }
    
    func setMagnifierState(_ value: Bool, waitAtMost: TimeInterval) async throws {
        if value == true {
            // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
            let uiAutomationSequence = UIAutomationSequence()
            let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

            let didSetInitialMagnifierZoomStyle = Session.shared.bool(for: .morphicDidSetInitialMagnifierZoomStyle) ?? false
            if didSetInitialMagnifierZoomStyle == false {
                do {
                    let waitForTimespan = UIAutomationApp.defaultMaximumWaitInterval
                    try await AppDelegate.shared.setInitialMagnifierZoomStyle(waitAtMost: waitForTimespan)
                } catch {
                    // NOTE: we must be able to set the initial magnifier zoom style; if we cannot, the feature cannot be known to work properly
                    throw MorphicError.unspecified
                }
            }

            // make sure that magnifier hotkeys are enabled
            do {
                let hotkeysEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getHotkeysEnabled()
                guard let hotkeysEnabled = hotkeysEnabledAsOptional else {
                    throw MorphicError.unspecified
                }
                
                if hotkeysEnabled == false {
                    let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                    try await AccessibilityZoomUIAutomationScript.setHotkeysEnabled(true, sequence: uiAutomationSequence, waitAtMost: waitForTimespan)
                }
            } catch let error {
                throw error
            }
            
            // since the magnifier zoom is being shown (i.e. enabled), set the cursor to the center of the display where the mouse cursor is located
            // NOTE: we might need to push a mouse movement message to the system so that the magnifier knows that the mouse has actually moved; or we might need to insert a UI-thread-nonblocking delay which lets the run loop catch up first (if that would remedy any mouse pointer location syncing issues)
            if let mousePointerLocation = MorphicSettings.MorphicMouse.getCurrentLocation() {
                if let currentDisplay = Display.displayContainingPoint(mousePointerLocation) {
                    do {
                        let _ = try MorphicSettings.MorphicMouse.movePointerToCenterOfDisplay(displayUuid: currentDisplay.uuid)
                    } catch {
                        // ignore any errors while moving pointer to the center of the display
                    }
                }
            }

            // activate the magnifier
            let magnifierIsEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled()
            if magnifierIsEnabledAsOptional == false || magnifierIsEnabledAsOptional == nil {
                try MorphicSettings.MagnifierZoomSettings.sendMagnifierToggleZoomHotkey()

                let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)

                // wait for the magnifier to show
                let magnifierShowSuccess = try await AsyncUtils.wait(atMost: waitForTimespan) {
                    guard let magnifierIsEnabled = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled() else {
                        return false
                    }

                    return magnifierIsEnabled == true
                }
                
                if magnifierShowSuccess == false {
                    throw MorphicError.unspecified
                }
            }
        } else /*if value == false*/ {
            // set up a UIAutomationSequence so that cleanup can occur once the sequence goes out of scope (e.g. auto-terminate the app)
            let uiAutomationSequence = UIAutomationSequence()
            let waitAbsoluteDeadline = ProcessInfo.processInfo.systemUptime + waitAtMost

            // make sure that magnifier hotkeys are enabled
            do {
                let hotkeysEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getHotkeysEnabled()
                guard let hotkeysEnabled = hotkeysEnabledAsOptional else {
                    throw MorphicError.unspecified
                }
                
                if hotkeysEnabled == false {
                    let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)
                    try await AccessibilityZoomUIAutomationScript.setHotkeysEnabled(true, sequence: uiAutomationSequence, waitAtMost: waitForTimespan)
                }
            } catch let error {
                throw error
            }
            
            // deactivate the magnifier
            // NOTE: to gracefully degrade for the user, we'll allow the sending of the toggle hotkey to try to turn "off" the magnifier if the magnifier is on and also if we cannot determine its state
            let magnifierIsEnabledAsOptional = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled()
            if magnifierIsEnabledAsOptional == true || magnifierIsEnabledAsOptional == nil {
                try MorphicSettings.MagnifierZoomSettings.sendMagnifierToggleZoomHotkey()

                let waitForTimespan = max(waitAbsoluteDeadline - ProcessInfo.processInfo.systemUptime, 0)

                // wait for the magnifier to hide
                let magnifierHideSuccess = try await AsyncUtils.wait(atMost: waitForTimespan) {
                    guard let magnifierIsEnabled = try MorphicSettings.MagnifierZoomSettings.getMagnifierEnabled() else {
                        return false
                    }

                    return magnifierIsEnabled == false
                }
                
                if magnifierHideSuccess == false {
                    throw MorphicError.unspecified
                }
            }
        }
    }
    
}

fileprivate struct LocalizedStrings {
    
    var prefix: String
    
    init(prefix: String) {
        self.prefix = prefix
    }
    
    func string(for suffix: String) -> String {
        return Bundle.main.localizedString(forKey: prefix + "." + suffix, value: nil, table: nil)
    }
}

fileprivate class QuickHelpDynamicTextProvider: QuickHelpContentProvider {
    
    var textProvider: () -> (String, String)?
    
    init(textProvider: @escaping () -> (String, String)?) {
        self.textProvider = textProvider
    }
    
    func quickHelpViewController() -> NSViewController? {
        guard let strings = textProvider() else{
            return nil
        }
        let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
        viewController.titleText = strings.0
        viewController.messageText = strings.1
        return viewController
    }
}

fileprivate class QuickHelpTextSizeBiggerProvider: QuickHelpContentProvider {
    
    init(/*display: Display?, */localized: LocalizedStrings) {
//        self.display = display
        self.localized = localized
    }
    
//    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        // NOTE: due to a limitation in Morphic 1.x, we use the current mouse pointer location as a proxy for the screen on which the
        //       Morphic bar is currently shown; in the future, we should get the current display for the MorphicBar WINDOW instead
        let display = getDisplayForMousePointer()

        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0 {
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == total - 1 {
            viewController.titleText = localized.string(for: "bigger.limit.help.title")
            viewController.messageText = localized.string(for: "bigger.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "bigger.help.title")
            viewController.messageText = localized.string(for: "bigger.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpTextSizeSmallerProvider: QuickHelpContentProvider {
    
    init(/*display: Display?, */localized: LocalizedStrings) {
//        self.display = display
        self.localized = localized
    }
//    var display: Display?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        // NOTE: due to a limitation in Morphic 1.x, we use the current mouse pointer location as a proxy for the screen on which the
        //       Morphic bar is currently shown; in the future, we should get the current display for the MorphicBar WINDOW instead
        let display = getDisplayForMousePointer()

        let viewController = QuickHelpStepViewController(nibName: "QuickHelpStepViewController", bundle: nil)
        let total = display?.numberOfSteps ?? 1
        var step = display?.currentStep ?? -1
        if step >= 0 {
            step = total - 1 - step
        }
        viewController.numberOfSteps = total
        viewController.step = step
        if step == 0 {
            viewController.titleText = localized.string(for: "smaller.limit.help.title")
            viewController.messageText = localized.string(for: "smaller.limit.help.message")
        } else {
            viewController.titleText = localized.string(for: "smaller.help.title")
            viewController.messageText = localized.string(for: "smaller.help.message")
        }
        return viewController
    }
}

fileprivate class QuickHelpVolumeUpProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "up.muted.help.title")
            viewController.messageText = localized.string(for: "up.muted.help.message")
        } else {
            if level >= 0.99 {
                viewController.titleText = localized.string(for: "up.limit.help.title")
                viewController.messageText = localized.string(for: "up.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "up.help.title")
                viewController.messageText = localized.string(for: "up.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeDownProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "down.muted.help.title")
            viewController.messageText = localized.string(for: "down.muted.help.message")
        } else {
            if level <= 0.01{
                viewController.titleText = localized.string(for: "down.limit.help.title")
                viewController.messageText = localized.string(for: "down.limit.help.message")
            } else {
                viewController.titleText = localized.string(for: "down.help.title")
                viewController.messageText = localized.string(for: "down.help.message")
            }
        }
        return viewController
    }
    
}

fileprivate class QuickHelpVolumeMuteProvider: QuickHelpContentProvider {
    
    init(audioOutput: AudioOutput?, localized: LocalizedStrings) {
        output = audioOutput
        self.localized = localized
    }
    
    var output: AudioOutput?
    var localized: LocalizedStrings
    
    func quickHelpViewController() -> NSViewController? {
        let level = output?.volume ?? 0.0
        let muted = output?.isMuted ?? false
        let viewController = QuickHelpVolumeViewController(nibName: "QuickHelpVolumeViewController", bundle: nil)
        viewController.volumeLevel = level
        viewController.muted = muted
        if muted {
            viewController.titleText = localized.string(for: "muted.help.title")
            viewController.messageText = localized.string(for: "muted.help.message")
        } else {
            viewController.titleText = localized.string(for: "mute.help.title")
            viewController.messageText = localized.string(for: "mute.help.message")
        }
        return viewController
    }
    
}

private extension NSImage {
    
    static func plus() -> NSImage {
        return NSImage(named: "SegmentIconPlus")!
    }
    
    static func minus() -> NSImage {
        return NSImage(named: "SegmentIconMinus")!
    }
    
}

private extension NSColor {
    
    // string must be formatted as #rrggbb
    static func createFromRgbHexString(_ rgbHexString: String) -> NSColor? {
        if rgbHexString.count != 7 {
            return nil
        }
        
        let hashStartIndex = rgbHexString.startIndex
        let redStartIndex = rgbHexString.index(hashStartIndex, offsetBy: 1)
        let greenStartIndex = rgbHexString.index(redStartIndex, offsetBy: 2)
        let blueStartIndex = rgbHexString.index(greenStartIndex, offsetBy: 2)
        
        let hashAsString = rgbHexString[hashStartIndex..<redStartIndex]
        guard hashAsString == "#" else {
            return nil
        }
        
        let redAsHexString = rgbHexString[redStartIndex..<greenStartIndex]
        guard let redAsInt = Int(redAsHexString, radix: 16),
            redAsInt >= 0,
            redAsInt <= 255 else {
            //
            return nil
        }
        let greenAsHexString = rgbHexString[greenStartIndex..<blueStartIndex]
        guard let greenAsInt = Int(greenAsHexString, radix: 16),
            greenAsInt >= 0,
            greenAsInt <= 255 else {
            return nil
        }
        let blueAsHexString = rgbHexString[blueStartIndex...]
        guard let blueAsInt = Int(blueAsHexString, radix: 16),
            blueAsInt >= 0,
            blueAsInt <= 255 else {
            //
            return nil
        }
        
        return NSColor(red: CGFloat(redAsInt) / 255.0, green: CGFloat(greenAsInt) / 255.0, blue: CGFloat(blueAsInt) / 255.0, alpha: 1.0)
    }
}
