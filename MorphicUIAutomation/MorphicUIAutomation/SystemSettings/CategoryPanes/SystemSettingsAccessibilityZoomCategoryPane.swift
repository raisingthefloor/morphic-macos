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

import Cocoa
import MorphicCore
import MorphicMacOSNative

internal class SystemSettingsAccessibilityZoomCategoryPane: SystemSettingsGroupUIElementWrapper {
    public required init(systemSettingsMainWindow: SystemSettingsMainWindow, groupUIElement: GroupUIElement) {
        super.init(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
    }
    
    public enum Checkbox: A11yUICheckboxIdentifier {
        case hoverText
        case useKeyboardShortcutsToZoom
        case useScrollGestureWithModifierKeysToZoom
        case useTrackpadGestureToZoom
        
        public func a11yUIIdentifier() -> String {
            switch self {
            case .hoverText:
                return "AX_HOVER_TEXT_ENABLE"
            case .useKeyboardShortcutsToZoom:
                return "AX_ZOOM_ENABLE_HOTKEYS"
            case .useScrollGestureWithModifierKeysToZoom:
                return "AX_ZOOM_ENABLE_GESTURE"
            case .useTrackpadGestureToZoom:
                return "AX_ZOOM_TRACKPAD"
            }
        }
    }
    
    public enum PopUpButton: A11yUIPopUpButtonIdentifier {
        case colorFilterType
        case zoomStyle

        public func a11yUIIdentifier() -> String {
            switch self {
            case .colorFilterType:
                return "AX_DISPLAY_FILTER_TYPE"
            case .zoomStyle:
                return "AX_ZOOM_STYLE_POPUP"
            }
        }
    }
}
