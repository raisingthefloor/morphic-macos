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

internal class SystemSettingsKeyboardShortcutsSheet: SystemSettingsGroupUIElementWrapper {
    public required init(systemSettingsMainWindow: SystemSettingsMainWindow, groupUIElement: GroupUIElement) {
        super.init(systemSettingsMainWindow: systemSettingsMainWindow, groupUIElement: groupUIElement)
    }
    
    public enum CategoryPane {
        case screenshots
    }
    
    private static func labelForCategory(_ category: CategoryPane) -> String {
        switch category {
        case .screenshots:
//            return "Screenshots"
            return "Screenshots shortcuts"
        }
    }
    
    private static func seekLabelForCategory(_ category: CategoryPane) -> String {
        switch category {
        case .screenshots:
            return "Save picture of screen as a file"
        }
    }

    public func navigateTo(_ pane: CategoryPane, waitAtMost: TimeInterval) async throws -> GroupUIElement {
        // NOTE: this function will navigate to the (sub)category specified as "pane", populating the right side of the sheet's splitview with the requested pane; it will then return the top-level group from that pane (i.e. the child of the right side of the split view, after navigation); this returned result may effectively be the same group UI element which was used by this class for navigation, due to the way that SwiftUI and System Settings swaps out panels in relation to the AX framework, so the caller should always re-navigate from the root (or from a known-synced state)

        // STEP 1: find the category through its value description; this will get the SwiftUI.AccessibilityNode (AXStaticText)
        // NOTE: due to SwiftUI's virtualization, we must capture the ancestors for the category so that we can navigate up the ancestor tree to find the row (to then select the row); otherwise the Parent attribute values may not be available (if they are not on-screen, scrolled in view, etc.)
        let categoryLabel = SystemSettingsKeyboardShortcutsSheet.labelForCategory(pane)
        //
        let categoryButtonComponentA11yUiElementWithLineage: [MorphicA11yUIElement]?
        do {
            categoryButtonComponentA11yUiElementWithLineage = try self.groupUIElement.accessibilityUiElement.dangerousFirstDescendantWithLineage(where: {
                guard $0.role == .button else {
                    return false
                }

                // NOTE: if we cannot get the value of the text, we intentionally ignore the issue
                guard let buttonLabel: String = try? $0.value(forAttribute: .description) else {
                    return false
                }

                return buttonLabel == categoryLabel
            })
        } catch let error {
            throw error
        }
        guard let categoryButtonComponentA11yUiElementWithLineage = categoryButtonComponentA11yUiElementWithLineage else {
            // could not find the category's row ("button")
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // STEP 2: find the category's row (so that we can select it)
        let categoryRowA11yUiElement: MorphicA11yUIElement?
        do {
            categoryRowA11yUiElement = try categoryButtonComponentA11yUiElementWithLineage.firstAncestorInLineage(role: .row)
        } catch let error {
            throw error
        }
        guard let categoryRowA11yUiElement = categoryRowA11yUiElement else {
            // could not find the category's row
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // STEP 3: convert the category's row to a UIElement, then select the row
        let categoryRowUIElement = RowUIElement(accessibilityUiElement: categoryRowA11yUiElement)
        do {
            try categoryRowUIElement.select()
        } catch let error {
            throw error
        }
        
        // STEP 5: wait for the category's contents to be loaded in the right pane (to confirm that the action was completed successfully)
        //
        let requiredStaticTextValue = SystemSettingsKeyboardShortcutsSheet.seekLabelForCategory(pane)
        //
        let navigationComplete: Bool
        do {
            navigationComplete = try await self.waitForNavigationToCompleteUsingStaticTextValue(requiredStaticTextValue, waitAtMost: waitAtMost)
        } catch let error {
            throw error
        }
        //
        if navigationComplete == false {
            throw SystemSettingsApp.NavigationError.unspecified
        }

        let detailsGroupUIElement: GroupUIElement
        do {
            (_, detailsGroupUIElement) = try self.findSheetSplitViewLeftAndRightGroups()
        } catch let error {
            throw error
        }
        
        // STEP 6: return the group which represents the right side of the split view
        return detailsGroupUIElement
    }
    
    private func waitForNavigationToCompleteUsingStaticTextValue(_ requiredStaticTextValue: String, waitAtMost: TimeInterval) async throws -> Bool {
        let navigationComplete: Bool
        do {
            navigationComplete = try await AsyncUtils.wait(atMost: waitAtMost, for: {
                // find the details group ui element
                let detailsGroupUIElement: GroupUIElement
                do {
                    (_, detailsGroupUIElement) = try self.findSheetSplitViewLeftAndRightGroups()
                } catch {
                    // if we encountered an error, just skip this iteration and try again
                    return false
                }

                // search through all static text elements in the group, trying to find one with the required text value
                let targetElement: MorphicA11yUIElement?
                do {
                    targetElement = try detailsGroupUIElement.accessibilityUiElement.dangerousFirstDescendant(where: {
                        guard $0.role == .staticText else {
                            return false
                        }
                        
                        // NOTE: if we cannot get the value of the text, we intentionally ignore the issue
                        guard let staticTextValue: String = try? $0.value(forAttribute: .value) else {
                            return false
                        }

                        return staticTextValue == requiredStaticTextValue
                    })
                } catch let error {
                    throw error
                }
                //
                return targetElement != nil
            })
        } catch let error {
            throw error
        }
        
        return navigationComplete
    }
    
    private func findSheetSplitViewLeftAndRightGroups() throws -> (leftGroup: GroupUIElement, rightGroup: GroupUIElement) {
        // STEP 1: search for the first split view in our UI hierarchy; this should be the split view which lists the categories on the left side of the split view and then shows the category on the right side of the split view
        //
        // find the group's split view
        let splitGroupA11yUiElement: MorphicA11yUIElement?
        do {
            splitGroupA11yUiElement = try self.groupUIElement.accessibilityUiElement.firstChild(role: NSAccessibility.Role.splitGroup)
        } catch let error {
            throw error
        }
        guard let splitGroupA11yUiElement = splitGroupA11yUiElement else {
            // could not find the split view
            throw SystemSettingsApp.NavigationError.unspecified
        }
        //
        // find the left and right panes in the split view
        let splitGroupUIElement = SplitGroupUIElement(accessibilityUiElement: splitGroupA11yUiElement)
        let splitGroupUIElements: [GroupUIElement]
        do {
            splitGroupUIElements = try splitGroupUIElement.splitGroupItemsAsGroupUIElements()
        }
        guard splitGroupUIElements.count == 2 else {
            throw SystemSettingsApp.NavigationError.unspecified
        }
        let leftGroup = splitGroupUIElements[0]
        let rightGroup = splitGroupUIElements[1]
        
        return (leftGroup: leftGroup, rightGroup: rightGroup)
    }

}
