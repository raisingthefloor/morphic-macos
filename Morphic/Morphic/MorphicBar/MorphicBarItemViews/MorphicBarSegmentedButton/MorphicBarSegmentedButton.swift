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

import Cocoa

// A control similar to a segmented control, but with momentary buttons and custom styling.
//
// Typically a control of this kind will have only two segments, like On and Off or
// Show and Hide.  The interaction is exactly as if the buttons were distinct.
// They are grouped together to emphasize their relationship to each other.
//
// The segments are styled similarly with different shades of a color depending
// on whether a segment is considered to be a primary segment or not.
//
// Given the styling and behavior constraints, it seemed better to make a custom control
// that draws a series of connected buttons than to use NSSegmentedControl.
class MorphicBarSegmentedButton: NSControl, MorphicBarWindowChildViewDelegate {
    // NOTE: in macOS 10.14 (and possibly newer releases), setting integerValue to a segment index # doesn't necessarily persist the value; selectedSegmentIndex serves the purpose explicitly instead
    var selectedSegmentIndex: Int = 0
    
    // MARK: - Creating a Segmented Button
    
    init(segments: [Segment]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        switch style {
        case .autoWidth:
            font = .morphicBold
        case .fixedWidth(_):
            font = .morphicBold // .morphicRegular
        }
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 3
        layer?.rasterizationScale = 2
        self.segments = segments
        updateButtons()
        
        // refuse first responder status (so that our child controls get selected in tab/shift-tab order instead)
        self.refusesFirstResponder = true
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    // MARK: - Style
    
    /// The color of text or icons on the segments
    ///
    /// - note: Since primary and secondary segments share the same title color,
    ///   their background colors should be similar enough that the title color works on both
    var titleColor: NSColor = .white
    
    // MARK: - Segments
    
    /// A segment's information
    struct Segment {
        
        /// The title to be shown on the segment, if any
        ///
        /// - important: `title` and `icon` are mutually exclusive.  If both sare specified,
        ///   the `title` property takes precedence
        var title: String?
        
        /// The icon to be shown on the segment, if any
        ///
        /// - important: `title` and `icon` are mutually exclusive.  If both sare specified,
        ///   the `title` property takes precedence
        var icon: NSImage?
        
        /// Indicates the color of the button segment
        let fillColor: NSColor
        
        var helpProvider: QuickHelpContentProvider?
        
        var style: MorphicBarControlItemStyle
        
        var learnMoreUrl: URL? = nil
        var learnMoreTelemetryCategory: String? = nil
        var quickDemoVideoUrl: URL? = nil
        var quickDemoVideoTelemetryCategory: String? = nil
        var settingsBlock: (() async throws -> Void)? = nil
        
        var getStateBlock: (() -> Bool)? = nil
        //
        struct StateUpdateNotificationInfo {
            var notificationName: NSNotification.Name
            var stateKey: String?
        }
        var stateUpdatedNotification: StateUpdateNotificationInfo? = nil
        
        var settingsMenuItemTitle = "Settings"        

        var accessibilityLabel: String?
        var accessibilityLabelByState: [NSControl.StateValue : String]? = [:]
        
        /// Create a segment with a title
        init(title: String, fillColor: NSColor, helpProvider: QuickHelpContentProvider?, accessibilityLabel: String?, learnMoreUrl: URL?, learnMoreTelemetryCategory: String?, quickDemoVideoUrl: URL?, quickDemoVideoTelemetryCategory: String?, settingsBlock: (() async throws -> Void)?, style: MorphicBarControlItemStyle) {
            self.title = title
            self.helpProvider = helpProvider
            self.fillColor = fillColor
            self.accessibilityLabel = accessibilityLabel
            self.learnMoreUrl = learnMoreUrl
            self.learnMoreTelemetryCategory = learnMoreTelemetryCategory
            self.quickDemoVideoUrl = quickDemoVideoUrl
            self.quickDemoVideoTelemetryCategory = quickDemoVideoTelemetryCategory
            self.settingsBlock = settingsBlock
            self.style = style
        }
        
        /// Create a segment with an icon
        init(icon: NSImage, fillColor: NSColor, helpProvider: QuickHelpContentProvider?, accessibilityLabel: String?, learnMoreUrl: URL?, learnMoreTelemetryCategory: String?, quickDemoVideoUrl: URL?, quickDemoVideoTelemetryCategory: String?, settingsBlock: (() async throws -> Void)?, style: MorphicBarControlItemStyle) {
            self.icon = icon
            self.helpProvider = helpProvider
            self.fillColor = fillColor
            self.accessibilityLabel = accessibilityLabel
            self.learnMoreUrl = learnMoreUrl
            self.learnMoreTelemetryCategory = learnMoreTelemetryCategory
            self.quickDemoVideoUrl = quickDemoVideoUrl
            self.quickDemoVideoTelemetryCategory = quickDemoVideoTelemetryCategory
            self.settingsBlock = settingsBlock
            self.style = style
        }
    }
    
    /// The segments on the control
    var segments = [Segment]() {
        didSet {
            updateButtons()
        }
    }
    
    // MARK: - Layout
    
    let horizontalMarginBetweenSegments = CGFloat(1.5)
    
    var style: MorphicBarControlItemStyle = .autoWidth

    override var isFlipped: Bool {
        return true
    }
    
    /// Amount of inset each button segment should have
    var contentInsets = NSEdgeInsets(top: 7, left: 9, bottom: 7, right: 9) {
        didSet {
            invalidateIntrinsicContentSize()
            for button in segmentButtons {
                button.contentInsets = contentInsets
            }
        }
    }
    
    override var intrinsicContentSize: NSSize {
        switch self.style {
        case .autoWidth:
            var size = NSSize(width: 0, height: contentInsets.top + contentInsets.bottom + 13)
            for button in segmentButtons {
                let buttonSize = button.intrinsicContentSize
                size.width += buttonSize.width
            }
            size.width += CGFloat(max(segmentButtons.count - 1, 0)) * horizontalMarginBetweenSegments
            return size
        case .fixedWidth(let segmentWidth):
            let totalWidth = (CGFloat(segments.count) * (segmentWidth + horizontalMarginBetweenSegments)) - horizontalMarginBetweenSegments
            let size = NSSize(width: totalWidth, height: contentInsets.top + contentInsets.bottom + 13)
            return size
        }
    }
    
    override func layout() {
        var frame = NSRect(origin: .zero, size: NSSize(width: 0, height: bounds.height))
        for button in segmentButtons {
            let buttonSize = button.intrinsicContentSize
            frame.size.width = buttonSize.width
            button.frame = frame
            frame.origin.x += frame.size.width + horizontalMarginBetweenSegments
        }
    }

    func childViewBecomeFirstResponder(sender: NSView) {
    	// alert the MorphicBarWindow that we have gained focus
        guard let superview = superview as? MorphicBarSegmentedButtonItemView else {
            return
        }
        superview.morphicBarView?.childViewBecomeFirstResponder(sender: sender)
    }
    
    func childViewResignFirstResponder() {
    	// alert the MorphicBarWindow that we have lost focus
        guard let superview = superview as? MorphicBarSegmentedButtonItemView else {
            return
        }
        superview.morphicBarView?.childViewResignFirstResponder()
    }

    // MARK: - Segment Buttons
    
    /// NSButton subclass that provides a custom intrinsic size with content insets
    class Button: NSButton {
        
        private var boundsTrackingArea: NSTrackingArea!
        
        public var style: MorphicBarControlItemStyle = .autoWidth
        
        var normalFillColor = NSColor.black
        var pressedFillColor = NSColor.gray
        var stateOnFillColor = NSColor.white
        //
        var normalBorderColor = NSColor.black
        var stateOnBorderColor = NSColor.black

        var normalContentColor = NSColor.white
        var stateOnContentColor = NSColor.black

        var getStateBlock: (() -> Bool)? = nil {
            didSet {
                // if we haven't loaded the initial state yet, and we now have a "get state block", load our initial button state now
                if let getStateBlock = self.getStateBlock {
                    if self.initialStateLoaded == false {
                        let initialState: Bool = getStateBlock()
                        self.toggleState = initialState ? .on : .off
                        self.initialStateLoaded = true
                    }
                }
            }
        }
        var initialStateLoaded: Bool = false
        //
        var stateUpdatedNotification: Segment.StateUpdateNotificationInfo? = nil {
            didSet {
                if self.stateUpdatedNotification != nil {
                    // subscribe to notification
                    NotificationCenter.default.addObserver(self, selector: #selector(Button.stateChanged(_:)), name: stateUpdatedNotification!.notificationName, object: nil)
                }
            }
            willSet {
                if newValue == nil && stateUpdatedNotification != nil {
                   // unsubscribe from notifications
                   // NOTE: in macOS 10.12+ this is technically not necessary (as the system will clean up for us when we are deallocated)
                   NotificationCenter.default.removeObserver(self, name: stateUpdatedNotification!.notificationName, object: nil)
                }
            }
        }
        
        @objc
        func stateChanged(_ aNotification: Notification) {
            let stateKey = self.stateUpdatedNotification?.stateKey
            
            var toggleStateAsBool: Bool? = nil 
	    if stateKey != nil {
            	if let state = aNotification.userInfo?[stateKey] as? Bool {
                    // we captured the new state directly from the notification (if present)
                    toggleStateAsBool = state
		}
            }
	    
	    if toggleStateAsBool == nil {
	        if let state = self.getStateBlock?() {
                    // if the notification does not contain the state data, we capture via our "getState" function
                    toggleStateAsBool = state
                } else {
                    // could not get state; log this error and return
                    NSLog("Failed to capture event-based settings state change")
                    return
                }
	    }
            
            DispatchQueue.main.async {
                self.toggleState = toggleStateAsBool! == true ? .on : .off
            }
        }
        
        var toggleState: NSControl.StateValue = .off {
            didSet {
                self.updateAccessibilityLabel()
                self.needsDisplay = true
            }
        }
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            // setup our color scheme
            let fillColor: NSColor
            if self.isHighlighted == true {
                // if our button is pressed, fill with the "pressedFillColor"
                fillColor = pressedFillColor
            } else {
                if self.toggleState == .on {
                    fillColor = stateOnFillColor
                } else {
                    fillColor = normalFillColor
                }
            }
            let borderColor: NSColor
            let contentColor: NSColor
            if self.toggleState == .on {
                borderColor = stateOnBorderColor
                contentColor = stateOnContentColor
            } else {
                borderColor = normalBorderColor
                contentColor = normalContentColor
            }
            let borderWidth: CGFloat = 3.0
            
            // fill the background of our button (and draw an appropriate border)
            let fillPath = NSBezierPath(rect: NSRect(origin: .zero, size: self.frame.size))
            //
            fillColor.setFill()
            fillPath.fill()

            // draw the text/image content
            let contentRect = NSRect(x: borderWidth, y: borderWidth, width: self.frame.width - (borderWidth * 2), height: self.frame.height - (borderWidth * 2))
            
            if let imageContent = image {
                // draw image content (self.image)
                
                let imageContentBoundingRect = NSRect(origin: .zero, size: CGSize(width: min(imageContent.size.width, contentRect.size.width), height: min(imageContent.size.height, contentRect.size.height)))
                let imageContentXPos: CGFloat = borderWidth + ((contentRect.width - imageContentBoundingRect.width) / 2)
                let imageContentYPos: CGFloat = borderWidth + ((contentRect.height - imageContentBoundingRect.height) / 2)
                let imageContentRect = NSRect(origin: CGPoint(x: imageContentXPos, y: imageContentYPos), size: imageContent.size)

                let recoloredImageContent = MorphicImageUtils.colorImage(imageContent, withColor: contentColor)
                
                recoloredImageContent.draw(in: imageContentRect)
            } else {
                // draw text content (self.title)

                let textParagraphStyle = NSMutableParagraphStyle()
                textParagraphStyle.alignment = .center
                //
                let textContent = self.title
		//
                let defaultTextFont = NSFont.systemFont(ofSize: 11)
                let textFont = self.font ?? defaultTextFont
                //
                let textAttributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: contentColor,
                    NSAttributedString.Key.paragraphStyle: textParagraphStyle
                ]
                
                // NOTE: textContentBoundingRect will be offset by the borderWidth
                // NOTE: we allow full-width text (and variable height); we do NOT resize the height to match
                let textContentBoundingRect = textContent.boundingRect(with: NSSize(width: contentRect.width, height: .infinity), options: [.usesLineFragmentOrigin], attributes: textAttributes)
                let textContentXPos: CGFloat = borderWidth + ((contentRect.width - textContentBoundingRect.width) / 2)
                var textContentYPos: CGFloat = borderWidth + ((contentRect.height - textContentBoundingRect.height) / 2)
                // adjust position for plus and minus symbols
                if textFont == .morphicHeavyForPlusMinusSymbols {
                    textContentYPos -= 1.5
                }
                //
                let textContentRect = NSRect(origin: CGPoint(x: textContentXPos, y: textContentYPos), size: textContentBoundingRect.size)
                
                // draw our text
                textContent.draw(with: textContentRect, options: [.usesLineFragmentOrigin], attributes: textAttributes, context: nil)
            }

            // stroke the outside of the button with our border color; we do this after drawing the content to ensure that the border is drawn on top of any content (i.e. so that overflowing content doesn't overflow the button)
            borderColor.setStroke()
            fillPath.lineWidth = borderWidth
            fillPath.stroke()
        }
        
        private func updateAccessibilityLabel() {
            if let newAccessibilityLabel = accessibilityLabelByState?[self.toggleState] {
                self.setAccessibilityLabel(newAccessibilityLabel)
            } else {
                self.setAccessibilityLabel(defaultAccessibilityLabel)
            }
        }
        
        var defaultAccessibilityLabel: String? {
            didSet {
                updateAccessibilityLabel()
            }
        }
        var accessibilityLabelByState: [NSControl.StateValue : String]? = [:]
        
        public override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            createBoundsTrackingArea()
        }
        
        required init?(coder: NSCoder) {
            return nil
        }
        
        public var contentInsets = NSEdgeInsetsZero {
            didSet{
                invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: NSSize {
            var size = super.intrinsicContentSize.roundedUp()
            switch style {
            case .autoWidth:
                size.width += contentInsets.left + contentInsets.right
            case .fixedWidth(let width):
                size.width = width
            }
            size.height += contentInsets.top + contentInsets.bottom
            return size
        }
        
        var showsHelp: Bool = true {
            didSet {
                createBoundsTrackingArea()
            }
        }
        
        var helpProvider: QuickHelpContentProvider?
        
        override func becomeFirstResponder() -> Bool {
            // alert the MorphicBarWindow that we have gained focus
            if let superview = superview as? MorphicBarSegmentedButton {
                superview.childViewBecomeFirstResponder(sender: self)
            }

            updateHelpWindow(wasSelectedByKeyboard: true)
            return super.becomeFirstResponder()
        }

        override func resignFirstResponder() -> Bool {
    	    // alert the MorphicBarWindow that we have lost focus
            if let superview = superview as? MorphicBarSegmentedButton {
                superview.childViewResignFirstResponder()
            }

            QuickHelpWindow.hide()
            return super.resignFirstResponder()
        }
        
        override func mouseEntered(with event: NSEvent) {
            updateHelpWindow()
        }
        
        override func mouseExited(with event: NSEvent) {
            QuickHelpWindow.hide()
        }
        
        public var learnMoreAction: Selector? = nil
        public var quickDemoVideoAction: Selector? = nil
        public var settingsAction: Selector? = nil
        //
        public var settingsMenuItemTitle: String! = nil
        //
        override func rightMouseDown(with event: NSEvent) {
            // create a pop-up menu for this button (segment)
            let popupMenu = NSMenu()
            if let _ = learnMoreAction {
                let learnMoreMenuItem = NSMenuItem(title: "Learn more", action: #selector(self.learnMoreMenuItemClicked(_:)), keyEquivalent: "")
                learnMoreMenuItem.target = self
                popupMenu.addItem(learnMoreMenuItem)
            }
            if let _ = quickDemoVideoAction {
                let quickDemoVideoMenuItem = NSMenuItem(title: "Quick Demo video", action: #selector(self.quickDemoVideoMenuItemClicked(_:)), keyEquivalent: "")
                quickDemoVideoMenuItem.target = self
                popupMenu.addItem(quickDemoVideoMenuItem)
            }
            if let _ = settingsAction {
                let settingsMenuItem = NSMenuItem(title: settingsMenuItemTitle, action: #selector(self.settingsMenuItemClicked(_:)), keyEquivalent: "")
                settingsMenuItem.target = self
                popupMenu.addItem(settingsMenuItem)
            }
            
            // pop up the menu
            popupMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
        
        @objc func learnMoreMenuItemClicked(_ sender: Any?) {
            super.sendAction(learnMoreAction, to: target)
        }

        @objc func quickDemoVideoMenuItemClicked(_ sender: Any?) {
            super.sendAction(quickDemoVideoAction, to: target)
        }

        @objc func settingsMenuItemClicked(_ sender: Any?) {
            super.sendAction(settingsAction, to: target)
        }

        override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
            guard super.sendAction(action, to: target) else {
                return false
            }
            updateHelpWindow()
            return true
        }
        
        func updateHelpWindow(wasSelectedByKeyboard: Bool = false) {
            if showsHelp == true {
                guard let viewController = helpProvider?.quickHelpViewController() else {
                    return
                }
                //
                let appDelegate = (NSApplication.shared.delegate as? AppDelegate)
                if wasSelectedByKeyboard == true || appDelegate?.currentKeyboardSelectedQuickHelpViewController != nil {
                    appDelegate?.currentKeyboardSelectedQuickHelpViewController = viewController
                }
                //
                QuickHelpWindow.show(viewController: viewController)
            }
        }
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            createBoundsTrackingArea()
        }
        
        private func createBoundsTrackingArea() {
            if boundsTrackingArea != nil {
                removeTrackingArea(boundsTrackingArea)
            }
            if showsHelp {
                boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
                addTrackingArea(boundsTrackingArea)
            }
        }
        
    }
    
    public var showsHelp: Bool = true {
        didSet {
            for button in segmentButtons {
                button.showsHelp = showsHelp
            }
        }
    }
    
    /// The list of buttons corresponding to the segments
    var segmentButtons = [Button]()
    
    /// Update the segment buttons
    private func updateButtons() {
        setNeedsDisplay(bounds)
        invalidateIntrinsicContentSize()
        removeAllButtons()
        for segment in segments {
            let button = self.createButton(for: segment)
            if let getStateBlock = segment.getStateBlock {
                button.getStateBlock = getStateBlock
            }
            add(button: button, showLearnMoreMenuItem: segment.learnMoreUrl != nil, showQuickDemoVideoMenuItem: segment.quickDemoVideoUrl != nil, showSettingsMenuItem: segment.settingsBlock != nil)
        }
        needsLayout = true
    }
    
    /// Create a button for a segment
    private func createButton(for segment: Segment) -> Button {
        let button = Button()
        button.bezelStyle = .regularSquare
//        bezelStyle = .shadowlessSquare // an alternate bezelStyle to consider
        button.isBordered = false
        button.contentInsets = contentInsets
        if let title = segment.title {
            button.title = title
        } else if let icon = segment.icon {
            button.image = icon
        }
        button.defaultAccessibilityLabel = segment.accessibilityLabel
        button.accessibilityLabelByState = segment.accessibilityLabelByState
        button.helpProvider = segment.helpProvider
        //
        button.normalFillColor = segment.fillColor
        button.pressedFillColor = NSColor(srgbRed: 102.0/255.0, green: 181.0/255.0, blue: 90.0/255.0, alpha: 1.0) // light green
        button.stateOnFillColor = .white
        //
        button.normalBorderColor = button.normalFillColor
        button.stateOnBorderColor = button.normalFillColor
        //
        button.normalContentColor = .white
        button.stateOnContentColor = .black
        //
        button.stateUpdatedNotification = segment.stateUpdatedNotification
        //
        button.style = segment.style
        switch segment.style {
        case .autoWidth:
            button.font = .morphicBold
        case .fixedWidth(_):
            button.font = .morphicBold // .morphicRegular
        }
        // special-case: if the label is the + or - symbol, use the special heavy font for those characters
        if segment.title == "+" || segment.title == "\u{2013}" {
            button.font = .morphicHeavyForPlusMinusSymbols
        }
        button.settingsMenuItemTitle = segment.settingsMenuItemTitle
        //
        return button
    }
    
    /// Remove all buttons
    private func removeAllButtons() {
        for i in (0..<segmentButtons.count).reversed(){
            removeButton(at: i)
        }
    }
    
    /// Remove a button at the give index
    ///
    /// - parameters:
    ///   - index: The index of the button to remove
    private func removeButton(at index: Int) {
        let button = segmentButtons[index]
        button.action = nil
        button.learnMoreAction = nil
        button.quickDemoVideoAction = nil
        button.settingsAction = nil
        button.target = nil
        segmentButtons.remove(at: index)
        button.removeFromSuperview()
    }
    
    /// Add a button
    ///
    /// - parameters:
    ///   - button: The button to add to the end of the list
    private func add(button: Button, showLearnMoreMenuItem: Bool, showQuickDemoVideoMenuItem: Bool, showSettingsMenuItem: Bool) {
        let index = segmentButtons.count
        button.tag = index
        button.target = self
        button.action = #selector(MorphicBarSegmentedButton.segmentAction)
        if showLearnMoreMenuItem == true {
            button.learnMoreAction = #selector(MorphicBarSegmentedButton.learnMoreMenuItemClicked(_:))
        }
        if showQuickDemoVideoMenuItem == true {
            button.quickDemoVideoAction = #selector(MorphicBarSegmentedButton.quickDemoVideoMenuItemClicked(_:))
        }
        if showSettingsMenuItem == true {
            button.settingsAction = #selector(MorphicBarSegmentedButton.settingsMenuItemClicked(_:))
        }
        segmentButtons.append(button)
        addSubview(button)
    }
    
    public func setButtonState(index: Int, stateAsBool: Bool) {
        if let buttonAtIndex = self.subviews[index] as? Button {
            buttonAtIndex.toggleState = stateAsBool ? .on : .off
        }
    }
    
    // MARK: - Actions
    
    /// Handles a segment button click and calls this control's action
    @objc
    private func segmentAction(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        integerValue = button.tag
        selectedSegmentIndex = button.tag
        sendAction(action, to: target)
    }
    
    @objc
    private func learnMoreMenuItemClicked(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        selectedSegmentIndex = button.tag
        let selectedSegment = segments[selectedSegmentIndex]
        guard let learnMoreUrl = selectedSegment.learnMoreUrl else {
            return
        }
        //
        defer {
            // NOTE: if we wanted to send the category that the user was learning more about, we could capture selectedSegment.learnMoreTelemetryCateogry--and send that category name via eventData
            TelemetryClientProxy.enqueueActionMessage(eventName: "learnMore")
        }
        //
        NSWorkspace.shared.open(learnMoreUrl)
    }

    @objc
    private func quickDemoVideoMenuItemClicked(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        selectedSegmentIndex = button.tag
        let selectedSegment = segments[selectedSegmentIndex]
        guard let quickDemoVideoUrl = selectedSegment.quickDemoVideoUrl else {
            return
        }
        //
        defer {
            // NOTE: if we wanted to send the category that the user was checking out (via quick demo videos), we could capture selectedSegment.quickDemoVideoTelemetryCategory--and send that category name via eventData
            TelemetryClientProxy.enqueueActionMessage(eventName: "quickDemoVideo")
        }
        //
        NSWorkspace.shared.open(quickDemoVideoUrl)
    }

    @objc
    private func settingsMenuItemClicked(_ sender: Any?) {
        guard let button = sender as? NSButton else {
            return
        }
        selectedSegmentIndex = button.tag
        let selectedSegment = segments[selectedSegmentIndex]
        guard let settingsBlock = selectedSegment.settingsBlock else {
            return
        }
        Task { try? await settingsBlock() }
    }
}
