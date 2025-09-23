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

import Cocoa
import MorphicService
import MorphicSettings

/// The View Controller for a MorphicBar showing a collection of actions the user can take
public class MorphicBarViewController: NSViewController {
    
    /// The close button
    @IBOutlet weak var closeButton: CloseButton!

    // MARK: - View Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        updateOrientationConstraints()
        morphicBarView.orientation = self.orientation
        morphicTrayView.orientation = .vertical
        morphicTrayView.controller = self
        BarBox.fillColor = self.getThemeBackgroundColor() ?? NSColor.black
        TrayBox.fillColor = self.getThemeBackgroundColor() ?? NSColor.black
        logoButton.image = self.getMorphieLogoImage()
        view.layer?.cornerRadius = 6
        NotificationCenter.default.addObserver(self, selector: #selector(MorphicBarViewController.sessionUserDidChange(_:)), name: .morphicSessionUserDidChange, object: Session.shared)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(MorphicBarViewController.appleInterfaceThemeDidChange(_:)), name: .appleInterfaceThemeChanged, object: nil)

        morphicBarView.tray = morphicTrayView
        TrayBox.isHidden = true
        expandTrayButton.isHidden = true
        collapseTrayButton.isHidden = true

        logoButton.setAccessibilityRole(.menuButton)
        logoButton.setAccessibilityLabel(logoButton.helpTitle)
        updatePositionConstraints()
    }
    
    // MARK: - Notifications
    
    @objc
    func appleInterfaceThemeDidChange(_ notification: NSNotification) {
        BarBox.fillColor = self.getThemeBackgroundColor() ?? NSColor.black
        TrayBox.fillColor = self.getThemeBackgroundColor() ?? NSColor.black
        logoButton.image = self.getMorphieLogoImage()
    }
    
    private func getMorphieLogoImage() -> NSImage {
        let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        let isDark = (appleInterfaceStyle?.lowercased() == "dark")
        let imageName = isDark ? "morphic-logo-dark" : "morphic-logo-light"
        return NSImage(named: imageName)!
    }
    
    private func getThemeBackgroundColor() -> NSColor? {
        let appleInterfaceStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        let isDark = (appleInterfaceStyle?.lowercased() == "dark")
        let backgroundColorName = isDark ? "MorphicBarDarkBackgroundColor" : "MorphicBarLightBackgroundColor"
        return NSColor(named: backgroundColorName)
    }
    
    @objc
    func sessionUserDidChange(_ notification: NSNotification) {
        guard let session = notification.object as? Session else {
            return
        }
    }
    
    // MARK: - Logo Button & Main Menu
    
    /// The MorphicBar's main menu, accessible via the Logo image button
    @IBOutlet var mainMenu: NSMenu!
    
    /// The boxes containing the MorphicBar and tray
    @IBOutlet weak var BarBox: NSBox!
    @IBOutlet weak var TrayBox: NSBox!
    
    /// The button that displays the Morphic logo
    @IBOutlet weak var logoButton: LogoButton!
    
    /// the tray expand collapse buttons
    @IBOutlet weak var expandTrayButton: NSButton!
    @IBOutlet weak var collapseTrayButton: NSButton!
    
    /// Action to show the main menu from the logo button
    @IBAction
    func showMainMenu(_ sender: Any?) {
        defer {
            TelemetryClientProxy.enqueueActionMessage(eventName: "showMenu")
        }

        AppDelegate.shared.mainMenu.popUp(positioning: nil, at: NSPoint(x: logoButton.bounds.origin.x, y: logoButton.bounds.origin.y + logoButton.bounds.size.height), in: logoButton)
    }
    
    /// Action to open the icon tray
    @IBAction
    func openTray(_ sender: Any?) {
        if morphicTrayView.isEmpty() {
            return
        }
        expandTrayButton.isHidden = true
        TrayBox.isHidden = false
        collapseTrayButton.isHidden = false
        morphicTrayView.collapsed = false
    }
    
    /// action to close the icon tray
    @IBAction
    func closeTray(_ sender: Any?) {
        collapseTrayButton.isHidden = true
        TrayBox.isHidden = true
        expandTrayButton.isHidden = morphicTrayView.isEmpty()
        morphicTrayView.collapsed = true
    }
    
    /// shrinks the window to fit the smallest box around the expanded bar
    public func shrinkFitWindow() {
        view.layoutSubtreeIfNeeded()
        var frame: NSRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        switch orientation {
        case .horizontal:
            var newFrameSize = frame.size.width + morphicBarView.intrinsicContentSize.width
            newFrameSize += 44 + 14 + 25 + 18
            frame.size.width = newFrameSize
            if closeButtonVisible {
                frame.size.width += 7 + 24
            }
            frame.size.height += morphicBarView.intrinsicContentSize.height + 7 + 7
        case .vertical:
            frame.size.width += morphicBarView.intrinsicContentSize.width + 7 + 7
            frame.size.width += morphicTrayView.intrinsicContentSize.width + 7 + 7 + 30
            frame.size.height += morphicBarView.intrinsicContentSize.height
        }
        let oframe = view.window?.frame
        if oframe != nil {
            frame.origin.x = (oframe?.origin.x)!
            frame.origin.y = (oframe?.origin.y)!
            if position == .bottomRight || position == .topRight {
                frame.origin.x += (oframe?.size.width)! - frame.size.width
            }
            view.window?.setFrame(frame, display: true)
        }
    }
    
    // MARK: - Orientation and orientation-related constraints
    
    public var orientation: MorphicBarOrientation = .horizontal {
        didSet {
            updateOrientationConstraints()
            morphicBarView?.orientation = self.orientation
        }
    }
    
    private let closeButtonVisible = true

    private func updateOrientationConstraints() {
        // first, configure the close button (on or off); we'll add it to the constraint list in the orientation switch logic below
        closeButtonWidthConstraint?.isActive = false
        if closeButtonVisible == true {
            closeButtonWidthConstraint = NSLayoutConstraint(item: closeButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24)
            closeButtonHeightConstraint = NSLayoutConstraint(item: closeButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 19)
        } else {
            closeButtonWidthConstraint = NSLayoutConstraint(item: closeButton!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            closeButtonHeightConstraint = NSLayoutConstraint(item: closeButton!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        }
        
        switch orientation {
        case .horizontal:
            // deactivate the vertical constraints
            logoButtonToMorphicBarViewVerticalTopConstraint?.isActive = false
            logoButtonToViewVerticalCenterXConstraint?.isActive = false
            viewToMorphicBarViewVerticalTrailingConstraint?.isActive = false
            viewToLogoButtonVerticalBottomConstraint?.isActive = false
            morphicBarViewToCloseButtonVerticalTopConstraint?.isActive = false

            // deactivate any old copies of our horizontal constraints
            logoButtonToMorphicBarViewHorizontalLeadingConstraint?.isActive = false
            logoButtonToViewHorizontalTopConstraint?.isActive = false
            closeButtonToLogoButtonHorizontalLeadingConstraint?.isActive = false
            viewToMorphicBarViewHorizontalBottomConstraint?.isActive = false
            morphicBarViewToViewHorizontalTopConstraint?.isActive = false

            logoButtonToMorphicBarViewHorizontalLeadingConstraint = NSLayoutConstraint(item: logoButton!, attribute: .leading, relatedBy: .equal, toItem: morphicBarView!, attribute: .trailing, multiplier: 1, constant: 18)
            logoButtonToViewHorizontalTopConstraint = NSLayoutConstraint(item: logoButton!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 7)
            closeButtonToLogoButtonHorizontalLeadingConstraint = NSLayoutConstraint(item: closeButton!, attribute: .leading, relatedBy: .equal, toItem: logoButton!, attribute: .trailing, multiplier: 1, constant: (closeButtonVisible == true ? 0 : 7))
            viewToMorphicBarViewHorizontalBottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: morphicBarView!, attribute: .bottom, multiplier: 1, constant: 7)
            morphicBarViewToViewHorizontalTopConstraint = NSLayoutConstraint(item: morphicBarView!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 7)

            self.view.addConstraints([
                logoButtonToMorphicBarViewHorizontalLeadingConstraint!,
                logoButtonToViewHorizontalTopConstraint!,
                closeButtonToLogoButtonHorizontalLeadingConstraint!,
                viewToMorphicBarViewHorizontalBottomConstraint!,
                morphicBarViewToViewHorizontalTopConstraint!,
                closeButtonWidthConstraint!,
                closeButtonHeightConstraint!
            ])
        case .vertical:
            // deactivate the horizontal constraints
            logoButtonToMorphicBarViewHorizontalLeadingConstraint?.isActive = false
            logoButtonToViewHorizontalTopConstraint?.isActive = false
            closeButtonToLogoButtonHorizontalLeadingConstraint?.isActive = false
            viewToMorphicBarViewHorizontalBottomConstraint?.isActive = false
            morphicBarViewToViewHorizontalTopConstraint?.isActive = false

            // deactivate any old copies of our vertical constraints
            logoButtonToMorphicBarViewVerticalTopConstraint?.isActive = false
            logoButtonToViewVerticalCenterXConstraint?.isActive = false
            viewToMorphicBarViewVerticalTrailingConstraint?.isActive = false
            viewToLogoButtonVerticalBottomConstraint?.isActive = false
            morphicBarViewToCloseButtonVerticalTopConstraint?.isActive = false 
            
            logoButtonToMorphicBarViewVerticalTopConstraint = NSLayoutConstraint(item: logoButton!, attribute: .top, relatedBy: .equal, toItem: morphicBarView!, attribute: .bottom, multiplier: 1, constant: 18)
            morphicBarViewToCloseButtonVerticalTopConstraint = NSLayoutConstraint(item: morphicBarView!, attribute: .top, relatedBy: .equal, toItem: closeButton!, attribute: .bottom, multiplier: 1, constant: 7)
            logoButtonToViewVerticalCenterXConstraint = NSLayoutConstraint(item: logoButton!, attribute: .centerX, relatedBy: .equal, toItem: morphicBarView!, attribute: .centerX, multiplier: 1, constant: 0)
            viewToMorphicBarViewVerticalTrailingConstraint = NSLayoutConstraint(item: BarBox!, attribute: .trailing, relatedBy: .equal, toItem: morphicBarView!, attribute: .trailing, multiplier: 1, constant: 7)
            viewToLogoButtonVerticalBottomConstraint = NSLayoutConstraint(item: BarBox!, attribute: .bottom, relatedBy: .equal, toItem: logoButton!, attribute: .bottom, multiplier: 1, constant: 7)

            self.view.addConstraints([
                logoButtonToMorphicBarViewVerticalTopConstraint!,
                logoButtonToViewVerticalCenterXConstraint!,
                viewToMorphicBarViewVerticalTrailingConstraint!,
                viewToLogoButtonVerticalBottomConstraint!,
                morphicBarViewToCloseButtonVerticalTopConstraint!,
                closeButtonWidthConstraint!,
                closeButtonHeightConstraint!
            ])
        }
        updatePositionConstraints()
    }
    
    // MARK: - Position and position-related constraints
    
    public var position: MorphicBarWindow.Position = .topRight {
        didSet {
            updatePositionConstraints()
            morphicTrayView.position = position
        }
    }
    
    private func updatePositionConstraints() {
        barToViewHorizontalConstraint?.isActive = false
        expandButtonToMorphicBarHorizontalConstraint?.isActive = false
        collapseButtonToMorphicBarHorizontalConstraint?.isActive = false
        trayToMorphicBarViewHorizontalConstraint?.isActive = false
        switch position {
        case .topLeft, .bottomLeft:
            barToViewHorizontalConstraint = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: BarBox!, attribute: .leading, multiplier: 1, constant: 0)
            expandButtonToMorphicBarHorizontalConstraint = NSLayoutConstraint(item: expandTrayButton!, attribute: .centerX, relatedBy: .equal, toItem: BarBox!, attribute: .trailing, multiplier: 1, constant: 0)
            collapseButtonToMorphicBarHorizontalConstraint = NSLayoutConstraint(item: collapseTrayButton!, attribute: .centerX, relatedBy: .equal, toItem: TrayBox!, attribute: .trailing, multiplier: 1, constant: 0)
            trayToMorphicBarViewHorizontalConstraint = NSLayoutConstraint(item: TrayBox!, attribute: .leading, relatedBy: .equal, toItem: BarBox!, attribute: .trailing, multiplier: 1, constant: 0)
            expandTrayButton.image = NSImage(named: "ExpandRight")!
            collapseTrayButton.image = NSImage(named: "ExpandLeft")!
        case .topRight, .bottomRight:
            barToViewHorizontalConstraint = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: BarBox!, attribute: .trailing, multiplier: 1, constant: 0)
            expandButtonToMorphicBarHorizontalConstraint = NSLayoutConstraint(item: expandTrayButton!, attribute: .centerX, relatedBy: .equal, toItem: BarBox!, attribute: .leading, multiplier: 1, constant: 0)
            collapseButtonToMorphicBarHorizontalConstraint = NSLayoutConstraint(item: collapseTrayButton!, attribute: .centerX, relatedBy: .equal, toItem: TrayBox!, attribute: .leading, multiplier: 1, constant: 0)
            trayToMorphicBarViewHorizontalConstraint = NSLayoutConstraint(item: TrayBox!, attribute: .trailing, relatedBy: .equal, toItem: BarBox!, attribute: .leading, multiplier: 1, constant: 0)
            expandTrayButton.image = NSImage(named: "ExpandLeft")!
            collapseTrayButton.image = NSImage(named: "ExpandRight")!
        }
        self.view.addConstraints([
            trayToMorphicBarViewHorizontalConstraint!,
            expandButtonToMorphicBarHorizontalConstraint!,
            collapseButtonToMorphicBarHorizontalConstraint!,
            barToViewHorizontalConstraint!
        ])
        BarBox.invalidateIntrinsicContentSize()
        TrayBox.invalidateIntrinsicContentSize()
        view.invalidateIntrinsicContentSize()
        view.needsLayout = true
    }
    
    // MARK: - Items
    
    /// The MorphicBar view and Tray view managed by this controller
    @IBOutlet weak var morphicBarView: MorphicBarView!
    @IBOutlet weak var morphicTrayView: MorphicBarTrayView!
    
    /// Orientation constraints (horizontal or vertical)
    var logoButtonToMorphicBarViewHorizontalLeadingConstraint: NSLayoutConstraint?
    var logoButtonToMorphicBarViewVerticalTopConstraint : NSLayoutConstraint?
    var logoButtonToViewHorizontalTopConstraint : NSLayoutConstraint?
    var logoButtonToViewVerticalCenterXConstraint: NSLayoutConstraint?
    var closeButtonToLogoButtonHorizontalLeadingConstraint: NSLayoutConstraint?
    //
    var viewToLogoButtonVerticalBottomConstraint: NSLayoutConstraint?
    var viewToMorphicBarViewHorizontalBottomConstraint: NSLayoutConstraint?
    var viewToMorphicBarViewVerticalTrailingConstraint: NSLayoutConstraint?
    var morphicBarViewToViewHorizontalTopConstraint: NSLayoutConstraint?
    var morphicBarViewToCloseButtonVerticalTopConstraint: NSLayoutConstraint?
    //
    var closeButtonWidthConstraint: NSLayoutConstraint?
    var closeButtonHeightConstraint: NSLayoutConstraint?
    
    /// Position constraints (left or right)
    var barToViewHorizontalConstraint: NSLayoutConstraint?
    var expandButtonToMorphicBarHorizontalConstraint: NSLayoutConstraint?
    var collapseButtonToMorphicBarHorizontalConstraint: NSLayoutConstraint?
    var trayToMorphicBarViewHorizontalConstraint: NSLayoutConstraint?

    /// The items that should be shown on the MorphicBar
    public var items = [MorphicBarItem]() {
        didSet {
            _ = view
            morphicBarView.removeAllItemViews()
            for item in items {
                if let itemView = item.view() {
                    itemView.showsHelp = showsHelp
                    morphicBarView.add(itemView: itemView)
                }
            }
            TrayBox.isHidden = true
            collapseTrayButton.isHidden = true
            expandTrayButton.isHidden = morphicTrayView.isEmpty()
            morphicTrayView.collapsed = true
        }
    }
    
    var showsHelp: Bool = true {
        didSet {
            logoButton.showsHelp = showsHelp
            for itemView in morphicBarView.itemViews {
                itemView.showsHelp = showsHelp
            }
        }
    }

    // NOTE: we are mirroring the NSView's accessibilityChildren function here to combine and proxy the list to our owner
    public func accessibilityChildren() -> [Any]? {
        var result = [Any]()
        for itemView in morphicBarView.itemViews {
            if let children = itemView.accessibilityChildren() {
                for child in children {
                    result.append(child)
                }
            }
        }
        if let logoButton = self.logoButton {
            result.append(logoButton)
        }
        for column in morphicTrayView.itemViewGrid {
            for itemView in column {
                if let children = itemView.accessibilityChildren() {
                    for child in children {
                        result.append(child)
                    }
                }
            }
        }
        // NOTE: we intentionally do _not_ add the closeButton to our list of accessibility children (as cmd+w will close the window)
        return result
    }

    @IBAction func closeButtonPressed(_ sender: NSButton) {
        AppDelegate.shared.morphicBarCloseButtonPressed()
    }
}



class CloseButton: NSButton {
    private var boundsTrackingArea: NSTrackingArea!
    
    private var isMouseHovering = false
    
    private let standardBackgroundColor: CGColor? = nil
    private let standardForegroundColor: CGColor = CGColor(red: 0x80 / 255.0, green: 0x80 / 255.0, blue: 0x80 / 255.0, alpha: 0xFF / 255.0)
    private var standardImage: NSImage!
    //
    private let hoverBackgroundColor: CGColor = CGColor(red: 0xE4 / 255.0, green: 0x14 / 255.0, blue: 0x2C / 255.0, alpha: 0xFF / 255.0)
    private let hoverForegroundColor: CGColor = CGColor.white
    private var hoverImage: NSImage!
    //
    private let pressedBackgroundColor: CGColor = CGColor(red: 0xF1 / 255.0, green: 0x70 / 255.0, blue: 0x7A / 255.0, alpha: 0xFF / 255.0)
    private let pressedForegroundColor: CGColor = CGColor.white
    private var pressedImage: NSImage!

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        // remove placeholder title
        self.title = ""
        self.imageScaling = .scaleNone
        self.imagePosition = .imageOnly
        
        // set up images
        self.standardImage = self.closeButtonImage(color: self.standardForegroundColor)
        self.hoverImage = self.closeButtonImage(color: self.hoverForegroundColor)
        self.pressedImage = self.closeButtonImage(color: self.pressedForegroundColor)

        redrawButton()
    }
    
    private func closeButtonImage(color: CGColor) -> NSImage? {
        let imageWidth = 11
        let imageHeight = 12
        //
        let imageXOffset = 1
        let imageWidthPadding = 1 // used to shift X, to correct centering issues; must be >= imageXOffset
        //
        let imageYOffset = 1
        let imageHeightPadding = 1 // used to shift S, to correct centering issues; must be >= imageYOffset
        //
        let topLeft = NSPoint(x: 0 + imageXOffset, y: imageHeight - 1 + imageYOffset)
        let topRight = NSPoint(x: imageWidth - 1 + imageXOffset, y: imageHeight - 1 + imageYOffset)
        let bottomLeft = NSPoint(x: 0 + imageXOffset, y: 0 + imageYOffset)
        let bottomRight = NSPoint(x: imageWidth - 1 + imageXOffset, y: 0 + imageYOffset)

        let image = NSImage(size: NSSize(width: imageWidth + imageWidthPadding, height: imageHeight + imageHeightPadding))
        image.lockFocus()

        guard let cgContext = NSGraphicsContext.current?.cgContext else {
            return nil
        }

        cgContext.setLineWidth(1)
        cgContext.setStrokeColor(color)
        
        cgContext.beginPath()
        cgContext.move(to: topLeft)
        cgContext.addLine(to: bottomRight)
        cgContext.closePath()
        //
        cgContext.move(to: bottomLeft)
        cgContext.addLine(to: topRight)
        cgContext.closePath()
        cgContext.strokePath()

        image.unlockFocus()

        return image
    }

    override func becomeFirstResponder() -> Bool {
        // do not accept first responder status
        return false
    }
    
    override func mouseEntered(with event: NSEvent) {
        self.isMouseHovering = true
        self.redrawButton()
        
        super.mouseEntered(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        self.isMouseHovering = false
        self.redrawButton()

        super.mouseExited(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.redrawButton()

        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        self.redrawButton()

        super.mouseUp(with: event)
    }
    
    private func redrawButton() {
        var isMouseDown = false
        if NSEvent.pressedMouseButtons & 0b01 != 0 {
            isMouseDown = true
        }
        
        if self.isMouseHovering == true {
            if isMouseDown == true {
                self.image = self.pressedImage
                self.layer?.backgroundColor = self.pressedBackgroundColor
            } else {
                self.image = self.hoverImage
                self.layer?.backgroundColor = self.hoverBackgroundColor
            }
        } else {
            self.image = self.standardImage
            self.layer?.backgroundColor = self.standardBackgroundColor
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        createBoundsTrackingArea()
    }

    private func createBoundsTrackingArea() {
        if self.boundsTrackingArea != nil {
            removeTrackingArea(self.boundsTrackingArea)
        }
        //
        self.boundsTrackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(self.boundsTrackingArea)
    }
}

class LogoButton: NSButton {
    
    private var boundsTrackingArea: NSTrackingArea!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createBoundsTrackingArea()
    }
    
    var showsHelp: Bool = true {
        didSet {
            createBoundsTrackingArea()
        }
    }
    
    @IBInspectable var helpTitle: String?
    @IBInspectable var helpMessage: String?
    
    override func becomeFirstResponder() -> Bool {
    	// alert the MorphicBarWindow that one of our controls has gained focus
        if let window = window as? MorphicBarWindow {
            window.currentFirstResponderChildView = self
        }

        updateHelpWindow(wasSelectedByKeyboard: true)
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
    	// alert the MorphicBarWindow that one of our controls has lost focus
        if let window = window as? MorphicBarWindow {
            window.currentFirstResponderChildView = nil 
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
    
    override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        
        // special for logo button: fire the "action" if right-clicked (in addition to the default left-click action event behavior)
        self.sendAction(self.action, to: self.target)
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
    
    func updateHelpWindow(wasSelectedByKeyboard: Bool = false) {
        guard let title = helpTitle, let message = helpMessage else {
            return
        }
        if showsHelp == true {
            let viewController = QuickHelpViewController(nibName: "QuickHelpViewController", bundle: nil)
            viewController.titleText = title
            viewController.messageText = message
            //
            let appDelegate = (NSApplication.shared.delegate as? AppDelegate)
            if wasSelectedByKeyboard == true || appDelegate?.currentKeyboardSelectedQuickHelpViewController != nil {
                appDelegate?.currentKeyboardSelectedQuickHelpViewController = viewController
            }
            //
            QuickHelpWindow.show(viewController: viewController)
        }
    }
    
}
