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

internal class SystemSettingsAccessibilityCategoryPane: SystemSettingsGroupUIElementWrapper {
    public required init(systemSettingsMainWindow: SystemSettingsMainWindow, groupUIElement: GroupUIElement) {
        super.init(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
    }
    
    public enum CategoryPane {
        case display
        case spokenContent
        case voiceOver
        case zoom
    }

    private static func identifierForCategory(_ category: CategoryPane) -> String {
        switch category {
        case .display:
            return "AX_FEATURE_DISPLAY"
        case .spokenContent:
            return "AX_FEATURE_SPOKENCONTENT"
        case .voiceOver:
            return "AX_FEATURE_VOICEOVER"
        case .zoom:
            return "AX_FEATURE_ZOOM"
        }
    }
    
    private static func windowTitleForCategory(_ category: CategoryPane) -> String {
        switch category {
        case .display:
            return "Display"
        case .spokenContent:
            return "Spoken Content"
        case .voiceOver:
            return "VoiceOver"
        case .zoom:
            return "Zoom"
        }
    }

    public func navigateTo(_ pane: CategoryPane, waitAtMost: TimeInterval) async throws -> GroupUIElement {
        // NOTE: this function will navigate to the (sub)category specified as "pane", populating the right side of the main splitview with the requested pane; it will then return the top-level group from that pane (i.e. the child of the right side of the split view, after navigation); this returned result may effectively be the same group UI element which was used by this class for navigation, due to the way that SwiftUI and System Settings swaps out panels in relation to the AX framework, so the caller should always re-navigate from the root (or from a known-synced state)

        // STEP 1: find the category through its identifier; this will get the AXButton element
        let categoryIdentifier = SystemSettingsAccessibilityCategoryPane.identifierForCategory(pane)
        //
        let categoryButtonA11yUiElement: MorphicA11yUIElement?
        do {
            categoryButtonA11yUiElement = try self.groupUIElement.accessibilityUiElement.descendant(identifier: categoryIdentifier)
        } catch let error {
            throw error
        }
        guard let categoryButtonA11yUiElement = categoryButtonA11yUiElement else {
            // could not find the category's button
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // STEP 2: convert the category's button to a UIElement, then press it
        let categoryButtonUIElement = ButtonUIElement(accessibilityUiElement: categoryButtonA11yUiElement)
        do {
            try categoryButtonUIElement.press()
        } catch let error {
            throw error
        }

        // STEP 3: wait for the category's contents to be loaded in the right pane (to confirm that the action was completed successfully)
        //
        let requiredWindowTitle = SystemSettingsAccessibilityCategoryPane.windowTitleForCategory(pane)
        //
        let navigationComplete: Bool
        do {
            navigationComplete = try await self.systemSettingsMainWindow.waitForNavigationToCompleteUsingWindowTitle(requiredWindowTitle, waitAtMost: waitAtMost, matchAnySuffix: true)
        } catch let error {
            throw error
        }
        //
        if navigationComplete == false {
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // STEP 4: search for the first split view in our UI hierarchy; this should be the split view which lists the categories on the left side of the split view and then shows the category on the right side of the split view
        let detailsGroupUIElement: GroupUIElement
        do {
            (_, detailsGroupUIElement) = try self.systemSettingsMainWindow.findMainSplitViewLeftAndRightGroups()
        } catch let error {
            throw error
        }
        
        // STEP 5: return the group which represents the right side of the split view
        return detailsGroupUIElement
    }
    
}
