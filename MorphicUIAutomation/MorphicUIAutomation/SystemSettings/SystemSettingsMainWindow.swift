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

internal class SystemSettingsMainWindow {
    private let windowUIElement: WindowUIElement
    
    public required init(windowUIElement: WindowUIElement) {
        self.windowUIElement = windowUIElement
    }
    
    public enum CategoryPane {
        case accessibility
        case appearance
        case displays
        case general
        case keyboard
        case mouse
        case trackpad
    }

    private static func identifierForCategory(_ category: CategoryPane) -> String {
        switch category {
        case .accessibility:
            return "com.apple.Accessibility-Settings.extension"
        case .appearance:
            return "com.apple.Appearance-Settings.extension"
        case .displays:
            return "com.apple.Displays-Settings.extension"
        case .general:
            return "com.apple.systempreferences.GeneralSettings"
        case .keyboard:
            return "com.apple.Keyboard-Settings.extension"
        case .mouse:
            return "com.apple.Mouse-Settings.extension"
        case .trackpad:
            return "com.apple.Trackpad-Settings.extension"
        }
    }
    
    private static func windowTitleForCategory(_ category: CategoryPane) -> String {
        if #available(macOS 15.0, *) {
            switch category {
            case .accessibility:
                return "Accessibility"
            case .appearance:
                return "Appearance"
            case .displays:
                return "Displays"
            case .general:
                // OBSERVATION: ideally in macOS 15.0 (and maybe 14.x?) we would look for the "general" header up top, since an empty string is problematic to match (i.e. could easily cause a false match)
                return ""
            case .keyboard:
                return "Keyboard"
            case .mouse:
                return "Mouse"
            case .trackpad:
                return "Trackpad"
            }
        } else {
            switch category {
            case .accessibility:
                return "Accessibility"
            case .appearance:
                return "Appearance"
            case .displays:
                return "Displays"
            case .general:
                return "General"
            case .keyboard:
                return "Keyboard"
            case .mouse:
                return "Mouse"
            case .trackpad:
                return "Trackpad"
            }
        }
    }

    public func navigateTo(_ pane: CategoryPane, waitAtMost: TimeInterval) async throws -> GroupUIElement {
        // NOTE: this function will navigate to the category specified as "pane", populating the right side of the main splitview with the requested pane; it will then return
        //       the top-level group from that pane (i.e. the child of the right side of the split view, after navigation)
        
        guard waitAtMost >= 0.0 else {
            fatalError("Argument 'atMost' cannot be a negative value")
        }
        let waitUntilTimestamp = ProcessInfo.processInfo.systemUptime + waitAtMost

        // STEP 1: search for the first split view in our UI hierarchy; this should be the split view which lists the categories on the left side of the split view and then shows the category on the right side of the split view
        let categoryGroupUIElement: GroupUIElement
        let detailsGroupUIElement: GroupUIElement
        do {
            (categoryGroupUIElement, detailsGroupUIElement) = try self.findMainSplitViewLeftAndRightGroups()
        } catch let error {
            throw error
        }
        
        // STEP 2: find the category through its identifier; this will get the SwiftUI.AccessibilityNode (AXStaticText)
        // NOTE: due to SwiftUI's virtualization, we must capture the ancestors for the category so that we can navigate up the ancestor tree to find the row (to then select the row); otherwise the Parent attribute values may not be available (if they are not on-screen, scrolled in view, etc.)
        let categoryIdentifier = SystemSettingsMainWindow.identifierForCategory(pane)
        //
        let categoryLabelComponentA11yUiElementWithLineage: [MorphicA11yUIElement]?
        do {
            categoryLabelComponentA11yUiElementWithLineage = try categoryGroupUIElement.accessibilityUiElement.descendantWithLineage(identifier: categoryIdentifier)
        } catch let error {
            throw error
        }
        guard let categoryLabelComponentA11yUiElementWithLineage = categoryLabelComponentA11yUiElementWithLineage else {
            // could not find the category's row ("button")
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // STEP 3: find the category's row (so that we can select it)
        let categoryRowA11yUiElement: MorphicA11yUIElement?
        do {
            categoryRowA11yUiElement = try categoryLabelComponentA11yUiElementWithLineage.firstAncestorInLineage(role: .row)
        } catch let error {
            throw error
        }
        guard let categoryRowA11yUiElement = categoryRowA11yUiElement else {
            // could not find the category's row
            throw SystemSettingsApp.NavigationError.unspecified
        }

        // NOTE: depending on whether we're using macOS 13.x or macOS 14.x, we'll need the window title for the category in one or more of the following steps
        let requiredWindowTitle = SystemSettingsMainWindow.windowTitleForCategory(pane)

        // STEP 4: if the row is not selected, select it; if the row is already selected, navigate to the category's root if necessary
        let categoryRowUIElement = RowUIElement(accessibilityUiElement: categoryRowA11yUiElement)
        var categoryRowIsSelected: Bool
        do {
            categoryRowIsSelected = try categoryRowUIElement.isSelected()
        } catch let error {
            throw error
        }
        if categoryRowIsSelected == true {
            // row is already selected; navigate to the category's root (using the "Back" button) if necessary
            // NOTE: we do not account for this time in our "max wait time"; we may want to reconsider how we provide/interpret timeout values
            var backButtonIsVisible: Bool
            var backButtonPressCount = 0
            let maxAllowedBackButtonPressCount = 8 // as a sanity check, we won't try pressing Back more than this many times
            repeat {
                let toolbarBackButton: ButtonUIElement?
                do {
                    toolbarBackButton = try self.findToolbarBackButton()
                } catch let error {
                    throw error
                }
                backButtonIsVisible = (toolbarBackButton != nil)
                
                guard let toolbarBackButton = toolbarBackButton else {
                    // toolbar back button does not exist, so our category is already at its main screen
                    break
                }
                
                // press the back button and then wait for the title to change
                let windowTitleBeforeBackButtonPress: String?
                do {
                    windowTitleBeforeBackButtonPress = try self.windowUIElement.title()
                } catch let error {
                    throw error
                }
                
                if windowTitleBeforeBackButtonPress != nil {
                    // press the back button, then wait up to 250ms for the window title to change
                    do {
                        try toolbarBackButton.press()
                    } catch let error {
                        throw error
                    }
                    do {
                        _ = try await AsyncUtils.wait(atMost: TimeInterval(0.250)) {
                            let windowTitle: String?
                            do {
                                windowTitle = try self.windowUIElement.title()
                            } catch let error {
                                throw error
                            }
                            guard let windowTitle = windowTitle else {
                                return false
                            }
                            
                            // return true if the window title has changed
                            return windowTitle != windowTitleBeforeBackButtonPress!
                        }
                    } catch let error {
                        throw error
                    }
                    
                    backButtonPressCount += 1
                } else {
                    // as a backup plan: if the current window title is not available, wait 250ms
                    try? await Task.sleep(nanoseconds: 250_000_000)

                    // even though we didn't actually press the back button, count this attempt against our maximum # of attempts
                    backButtonPressCount += 1
                }
                
                if #available(macOS 14.0, *) {
                    // macOS 14.0 and newer
                    let windowTitleMatches: Bool
                    do {
                        windowTitleMatches = try self.windowTitleMatches(requiredWindowTitle)
                    } catch let error {
                        throw error
                    }
                    //
                    if windowTitleMatches == true {
                        // we have navigated up to the specified category's main pane; on macOS 14.0 and newer, pressing Back again could lead to another category
                        break
                    }
                } else {
                    // macOS 13.x
                    //
                    // for macOS 13.x, we navigate all the way to the root; using the 14.x search mechanism (stopping when the category matches) could also work, but out of an abundance of caution we aren't modifying 13.x code unless we find/experience actual bugs in it.
                }
            } while backButtonPressCount < maxAllowedBackButtonPressCount
            
            if #available(macOS 14.0, *) {
                // macOS 14.0 or newer
                //
                // NOTE: on macOS 14.0 and newer, we don't necessarily expect the back button to be disabled/invisible once we reach the root pane of the category
            } else {
                // macOS 13.x
                //
                // if we were unable to move to the root of the category, raise an error
                guard backButtonIsVisible == false else {
                    throw SystemSettingsApp.NavigationError.unspecified
                }
            }
        } else {
            // row is not selected; select it now
            do {
                try categoryRowUIElement.select()
            } catch let error {
                throw error
            }
        }
 
        // STEP 5: wait for the category's contents to be loaded in the right pane (to confirm that the action was completed successfully)
        //
        let navigationComplete: Bool
        do {
            // NOTE: we will check for the navigation to be completed for at least one iteration (i.e. wait time of "0")
            let remainingWaitTime = max(waitUntilTimestamp - ProcessInfo.processInfo.systemUptime, 0)
            navigationComplete = try await self.waitForNavigationToCompleteUsingWindowTitle(requiredWindowTitle, waitAtMost: remainingWaitTime, matchAnySuffix: true)
        } catch let error {
            throw error
        }
        //
        if navigationComplete == false {
            throw SystemSettingsApp.NavigationError.unspecified
        }
        
        // STEP 6: return the group which represents the right side of the split view
        return detailsGroupUIElement
    }
    
    internal func findToolbar() throws -> ToolbarUIElement {
        // search for the toolbar at the top level of our UI hierarchy
        let toolbarA11yUiElement: MorphicA11yUIElement?
        do {
            toolbarA11yUiElement = try self.windowUIElement.accessibilityUiElement.firstChild(role: NSAccessibility.Role.toolbar)
        } catch let error {
            throw error
        }
        guard let toolbarA11yUiElement = toolbarA11yUiElement else {
            // could not find the toolbar
            throw SystemSettingsApp.NavigationError.unspecified
        }

        let toolbarUIElement = ToolbarUIElement(accessibilityUiElement: toolbarA11yUiElement)
        return toolbarUIElement
    }
    
    // NOTE: as the toolbar button is only sometimes present, we consider its current exclusion from the logical hierarchy to not be an error--and we simply return nil instead
    internal func findToolbarBackButton() throws -> ButtonUIElement? {
        // STEP 1: find the toolbar at the top leve of our UI hierarchy
        let toolbarUIElement: ToolbarUIElement
        do {
            toolbarUIElement = try self.findToolbar()
        } catch let error {
            throw error
        }
        
        // STEP 2: find the Back button (which is a child of the toolbar)
        let backButtonA11yUIElement: MorphicA11yUIElement?
        do {
            if #available(macOS 14.0, *) {
                // macOS 14.0 and newer
                backButtonA11yUIElement = try toolbarUIElement.accessibilityUiElement.dangerousFirstDescendant(where: {
                    guard $0.role == .button else {
                        return false
                    }
                    
                    guard let buttonLabel: String = try? $0.value(forAttribute: .description) else {
                        return false
                    }
                    
                    return buttonLabel == "Back"
                })
            } else {
                // macOS 13.x
                backButtonA11yUIElement = try toolbarUIElement.accessibilityUiElement.descendant(identifier: "go back", maxDepth: 1)
            }
        } catch let error {
            throw error
        }
        guard let backButtonA11yUIElement = backButtonA11yUIElement else {
            return nil
        }
        
        let buttonUIElement = ButtonUIElement(accessibilityUiElement: backButtonA11yUIElement)
        return buttonUIElement
    }
    
    internal func findMainSplitViewLeftAndRightGroups() throws -> (leftGroup: GroupUIElement, rightGroup: GroupUIElement) {
        // STEP 1: search for the first split view in our UI hierarchy; this should be the split view which lists the categories on the left side of the split view and then shows the category on the right side of the split view
        //
        // find the window's main group element (which hosts the split view)
        let groupA11yUiElement: MorphicA11yUIElement?
        do {
            groupA11yUiElement = try self.windowUIElement.accessibilityUiElement.firstChild(role: NSAccessibility.Role.group)
        }
        guard let groupA11yUiElement = groupA11yUiElement else {
            // could not find the topmost group (which is the parent of the target split view)
            throw SystemSettingsApp.NavigationError.unspecified
        }
        //
        // find the main group's split view
        let splitGroupA11yUiElement: MorphicA11yUIElement?
        do {
            splitGroupA11yUiElement = try groupA11yUiElement.firstChild(role: NSAccessibility.Role.splitGroup)
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
    
    internal func waitForNavigationToCompleteUsingWindowTitle(_ requiredWindowTitle: String, waitAtMost: TimeInterval, matchAnySuffix: Bool = false) async throws -> Bool {
        let navigationComplete: Bool
        do {
            navigationComplete = try await AsyncUtils.wait(atMost: waitAtMost, for: {
                do {
                    return try self.windowTitleMatches(requiredWindowTitle, matchAnySuffix: matchAnySuffix)
                } catch let error {
                    throw error
                }
            })
        } catch let error {
            throw error
        }
        
        return navigationComplete
    }
    
    internal func windowTitleMatches(_ requiredWindowTitle: String, matchAnySuffix: Bool = false) throws -> Bool {
        let windowTitle: String?
        do {
            windowTitle = try self.windowUIElement.title()
        } catch let error {
            throw error
        }
        guard let windowTitle = windowTitle else {
            return false
        }
        //
        if matchAnySuffix == false {
            return windowTitle == requiredWindowTitle
        } else {
            return windowTitle.starts(with: requiredWindowTitle)
        }
    }
    
    public func sheet() throws -> SheetUIElement? {
        // search for the single sheet at the top of our window's UI hierarchy; this should be the split view which lists the categories on the left side of the split view and then shows the category on the right side of the split view
        //
        // find the window's single sheet element
        let sheetA11yUiElement: MorphicA11yUIElement?
        do {
            sheetA11yUiElement = try self.windowUIElement.accessibilityUiElement.onlyChild(role: NSAccessibility.Role.sheet)
        } catch let error {
            throw error
        }
        guard let sheetA11yUiElement = sheetA11yUiElement else {
            // could not find a sheet
            return nil
        }

        let result = SheetUIElement(accessibilityUiElement: sheetA11yUiElement)
        return result
    }

}
