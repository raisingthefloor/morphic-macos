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

class MorphicBarButtonItemView: NSButton, MorphicBarItemViewProtocol {
    // MorphicBarItemView protocol requirements
    //
    var showsHelp: Bool = true
    //
    // NOTE: the following must also be implemented in all classes conforming to MorphicBarItemViewProtocol
    public override var isFlipped: Bool {
        return true
    }
    //
    public weak var morphicBarView: MorphicBarView?
    //
    public var contentFrames: [CGRect] {
        var result: [CGRect] = []
        result.append(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        return result
    }

    //
    
    let fixedHeightInHorizontalBar: CGFloat = 44
    let maximumWidth: CGFloat = 100
    
    //
    
    private var titleBoxLayer: CAShapeLayer!
    private var iconCircleLayer: CAShapeLayer!
    private var iconImageLayer: CALayer!
    private var titleTextLayer: CATextLayer!

    init(label: String, labelColor: NSColor?, fillColor: NSColor?, icon: MorphicBarButtonItemIcon?, iconColor: NSColor?) {
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 96))
        //
        self.title = label
//        self.font = .morphicRegular
        self.font = .morphicBold
        self.fontColor = labelColor
        // NOTE: if fillColor is nil, the default color is used instead
        if let fillColor = fillColor {
            self.fillColor = fillColor
        }
        self.icon = icon
        // NOTE: if iconColor is nil, then the icon is filled with the fillColor instead
        self.iconColor = iconColor
        //
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //
        initialize()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        //
        initialize()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // NOTE: we draw a background so that macOS doesn't draw a button background (including 3D border) for us
        layer?.backgroundColor = self.backgroundColor?.cgColor ?? .clear
    }

    private func initialize() {
        // make our view a layer-based view
        self.wantsLayer = true

        // create and add each view in order (back to front)
        
        self.titleBoxLayer = CAShapeLayer()
        self.layer?.addSublayer(self.titleBoxLayer)

        self.iconCircleLayer = CAShapeLayer()
        self.layer?.addSublayer(self.iconCircleLayer)

        self.iconImageLayer = CALayer()
        self.layer?.addSublayer(self.iconImageLayer)

        self.titleTextLayer = CATextLayer()
        self.layer?.addSublayer(self.titleTextLayer)
        
        // configure each layer with default values
        configureTitleBoxLayer()
        configureIconCircleLayer()
        configureIconImageLayer()
        configureTitleTextLayer()
    }
    
    private func configureIconCircleLayer() {
        guard let _ = self.icon else {
            self.iconImageLayer.contents = nil
            return
        }

        // calculate the diameter and bounds of the circle around our icon
        let iconCircleDiameter = calculateIconCircleDiameter()
        let iconCircleRadius = iconCircleDiameter / 2.0
        let iconCircleBounds = calculateIconCircleBounds()
        let iconCircleCenter = NSPoint(x: iconCircleBounds.midX, y: iconCircleBounds.midY)

        // sanity-check the stroke width of our icon circle
        let maxIconCircleStrokeWidth: CGFloat = iconCircleDiameter / 2.0
        let iconCircleStrokeWidthToUse = min(self.iconCircleStrokeWidth, maxIconCircleStrokeWidth)
        
        // create a new layer
        let newIconCircleLayer = CAShapeLayer()
        // and create a sublayer for the "cut out" center of the circle
        let insideCircleLayer = CAShapeLayer()
        
        // configure the layers to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newIconCircleLayer.contentsScale = backingScaleFactor
            insideCircleLayer.contentsScale = backingScaleFactor
        }

        // first: draw and fill the outer circle diameter
        let outerCirclePath = CGMutablePath()
        outerCirclePath.addArc(center: iconCircleCenter, radius: iconCircleRadius, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        newIconCircleLayer.path = outerCirclePath
        newIconCircleLayer.fillColor = self.fillColor.cgColor

        // then: create the inner circle (white fill)
        let innerCirclePath = CGMutablePath()
        innerCirclePath.addArc(center: iconCircleCenter, radius: iconCircleRadius - iconCircleStrokeWidthToUse, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        insideCircleLayer.path = innerCirclePath
        insideCircleLayer.fillColor = NSColor.white.cgColor
        //
        newIconCircleLayer.addSublayer(insideCircleLayer)

        self.layer?.replaceSublayer(self.iconCircleLayer, with: newIconCircleLayer)
        self.iconCircleLayer = newIconCircleLayer
    }

    private func configureIconImageLayer() {
        guard let iconAsNonOptional = self.icon else {
            self.iconImageLayer.contents = nil
            return
        }
        
        // get the size of our frame
        let frameSize = self.frame.size

        // calculate the diameter of the circle around our icon
        let iconCircleDiameter = calculateIconCircleDiameter()
        
        // calculate the size of our icon
//        let iconMaxWidthAndMaxHeight: CGFloat = floor((iconCircleDiameter - 2) * 0.6) // official spec
        let iconMaxWidthAndMaxHeight: CGFloat = floor((iconCircleDiameter - 2) * 0.66) // observed behavior of Morphic for Windows

        // calculate actual width and height based on image's width to height ratio
        let pdfData = NSData(contentsOfFile: iconAsNonOptional.pathToImage)! as Data
        let pdfImageRep = NSPDFImageRep(data: pdfData)!
        let imageFrameSize = calculateImageFrameSizeForPdf(pdfBounds: pdfImageRep.bounds, maxWidth: iconMaxWidthAndMaxHeight, maxHeight: iconMaxWidthAndMaxHeight)
        
        // calculate the position of our icon
        let iconXPosition: CGFloat = (frameSize.width - imageFrameSize.width) / 2
        let iconYPosition: CGFloat = (iconCircleDiameter - imageFrameSize.height) / 2

        // create a new layer
        let newIconLayer = CAShapeLayer()

        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newIconLayer.contentsScale = backingScaleFactor
        }

        // frame
        newIconLayer.frame = NSRect(x: iconXPosition, y: iconYPosition, width: imageFrameSize.width, height: imageFrameSize.height)
        // background
        newIconLayer.backgroundColor = .clear
        // contents
        
        let nsImage = NSImage(size: NSSize(width: imageFrameSize.width, height: imageFrameSize.height), flipped: false) { (imageRect) -> Bool in
            pdfImageRep.draw(in: imageRect)
            return true
        }
        // NOTE: we have disabled the recoloring feature as the new bar editor uses full-color images
//        let recoloredNsImage = MorphicImageUtils.colorImage(nsImage, withColor: self.iconColor ?? self.fillColor)
//        newIconLayer.contents = recoloredNsImage
        newIconLayer.contents = nsImage

        self.layer?.replaceSublayer(self.iconImageLayer, with: newIconLayer)
        self.iconImageLayer = newIconLayer
    }
    
    private func configureTitleBoxLayer() {
        // calculate the size of our title's background rounded rectangle box
        let titleBoxBounds: CGRect = calculateTitleBoxBounds()

        // create a new layer
        let newTitleBoxLayer = CAShapeLayer()
        
        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newTitleBoxLayer.contentsScale = backingScaleFactor
        }

        // sanity check our titlebox corner radius
        let maxTitleBoxCornerRadius: CGFloat = min(titleBoxBounds.width, titleBoxBounds.height) / 2.0
        
        // first: draw the rounded rectangle box behind our title
        let titleBoxPath = CGMutablePath()
        titleBoxPath.addRoundedRect(in: titleBoxBounds, cornerWidth: min(self.roundedRectangeCornerRadius, maxTitleBoxCornerRadius), cornerHeight: min(self.roundedRectangeCornerRadius, maxTitleBoxCornerRadius))
        newTitleBoxLayer.path = titleBoxPath
        newTitleBoxLayer.fillColor = self.fillColor.cgColor
        
        self.layer?.replaceSublayer(self.titleBoxLayer, with: newTitleBoxLayer)
        self.titleBoxLayer = newTitleBoxLayer
    }

    private func configureTitleTextLayer() {
        guard let titleFont = self.font else {
            return
        }

        // get size and lines of our title
        let (titleTextPixelWidth, titleTextPixelHeight, titleLines) = measureAndSplitText(self.title, maxWidth: self.maximumWidth, maxHeight: self.calculateMaximumTextHeight())
        let titleMultilineText = titleLines.joined(separator: "\n")
        
        // calculate the bounds of our title text
        let titleTextBounds = calculateTitleTextBounds()
        
        // create a new layer
        let newTitleTextLayer = CATextLayer()

        // configure the layer to be drawn using the proper (e.g. Retina vs. non-Retina) scale factor
        if let backingScaleFactor = self.backingScaleFactor() {
            newTitleTextLayer.contentsScale = backingScaleFactor
        }

        // frame
        newTitleTextLayer.frame = NSRect(x: titleTextBounds.minX, y: titleTextBounds.minY, width: titleTextPixelWidth, height: titleTextPixelHeight)
        // font properties
        newTitleTextLayer.font = titleFont
        newTitleTextLayer.fontSize = titleFont.pointSize
        newTitleTextLayer.foregroundColor = fontColor?.cgColor ?? .white
        //
        // title string
        newTitleTextLayer.alignmentMode = .center
        newTitleTextLayer.string = titleMultilineText
        
        self.layer?.replaceSublayer(self.titleTextLayer, with: newTitleTextLayer)
        self.titleTextLayer = newTitleTextLayer
    }
    
    // MARK: size/position calculations
    
    // NOTE: if this function is called without an explicit frame width, the view's current frame width is used
    private func calculateIconCircleDiameter(usingFrameWidth customFrameWidth: CGFloat? = nil) -> CGFloat {
        // get the size of our frame
        let frameSize = self.frame.size

        let frameWidthForCalculation = customFrameWidth ?? frameSize.width
        
        // calculate the size of the circle around our icon
        let circleDiameter = floor(frameWidthForCalculation * (2.0/3))
        
        return circleDiameter
    }
    
    private func calculateIconCircleBounds() -> NSRect {
        // get the size of our frame
        let frameSize = self.frame.size

        let iconCircleDiameter = calculateIconCircleDiameter()

        let iconCircleXPosition: CGFloat = (frameSize.width - iconCircleDiameter) / 2.0
        let iconCircleYPosition: CGFloat = 0.0

        let iconCircleBounds = NSRect(x: iconCircleXPosition, y: iconCircleYPosition, width: iconCircleDiameter, height: iconCircleDiameter)
        
        return iconCircleBounds
    }

    // NOTE: this function calculates the title box size based on the contents of the box
    private func calculateTitleBoxSize() -> NSSize {
        let orientation = self.morphicBarView?.orientation ?? .horizontal

        // get the size of our frame
        let frameSize = self.frame.size

        // calculate the height of our text in pixels
        let (_, titleTextPixelHeight, _) = measureAndSplitText(title, maxWidth: self.maximumWidth, maxHeight: self.calculateMaximumTextHeight())

        // calculate the size of our icon (if any) in pixels)
        let iconCircleDiameter = calculateIconCircleDiameter()
        
        let titleBoxSize: NSSize
        if icon != nil {
            // NOTE: 2/3 of the circle is above the box; the remainder of the circle is inside the box
            titleBoxSize = NSSize(width: frameSize.width, height: titleTextPixelHeight + self.titleBottomPadding + ((iconCircleDiameter * 2.0)/3))
        } else {
            if orientation == .horizontal {
                titleBoxSize = NSSize(width: frameSize.width, height: self.fixedHeightInHorizontalBar)
            } else /* if orientation == .vertical */ {
                titleBoxSize = NSSize(width: frameSize.width, height: titleTextPixelHeight + (self.titleBottomPadding * 2))
            }
        }
        
        return titleBoxSize
    }
    
    private func calculateTitleBoxBounds() -> NSRect {
        // get the size of our frame
        let frameSize = self.frame.size

        // calculate the size of our title's background rounded rectangle box
        let titleBoxSize = calculateTitleBoxSize()
        let titleBoxBounds: NSRect
        titleBoxBounds = NSRect(x: 0.0, y: frameSize.height - titleBoxSize.height, width: titleBoxSize.width, height: titleBoxSize.height)

        return titleBoxBounds
    }
    
    private func measureAndSplitText(_ text: String, maxWidth: CGFloat, maxHeight: CGFloat? = nil) -> (pixelWidth: CGFloat, pixelHeight: CGFloat, lines: [String]) {
        // establish the maximum number of lines we're willing to support in this control
        let maximumNumberOfLines = 2
        
        var lines: [String] = []
        var remainingText = text
        //
        var numberOfWordsInCurrentLine = 0
        var currentLine = ""

        // measure each word sequence in our title (to make sure each one fits on a single line); replace text with elipses where necessary
        while remainingText.count > 0 && lines.count < maximumNumberOfLines {
            var nextWord: String
            var whitespaceCharacter: Character? = nil
            var wordIsFollowedByNewline = false
            if let nextSpaceIndex = remainingText.firstIndex(of: " ") {
                whitespaceCharacter = " "
                if (nextSpaceIndex > remainingText.startIndex) {
                    // space after some characters
                    let nextWordEndIndex = remainingText.index(before: nextSpaceIndex)
                    nextWord = String(remainingText[...nextWordEndIndex])
                } else {
                    // space followed by zero or more characters
                    nextWord = String()
                }
            } else if let newlineIndex = remainingText.firstIndex(of: "\n") {
                whitespaceCharacter = "\n"
                if (newlineIndex > remainingText.startIndex) {
                    // newline after some characters
                    let nextWordEndIndex = remainingText.index(before: newlineIndex)
                    nextWord = String(remainingText[...nextWordEndIndex])
                } else {
                    // newline followed by zero or more characters
                    nextWord = ""
                }
                wordIsFollowedByNewline = true
            } else {
                nextWord = String(remainingText[..<remainingText.endIndex])
                whitespaceCharacter = nil
            }

            // append the next word (plus the trailing space)
            var proposedCurrentLine = currentLine + (currentLine != "" ? " " : "") + nextWord
            var numberOfWordsInProposedCurrentLine = numberOfWordsInCurrentLine + 1
            
            var finishCurrentLineAndStartNewLine = false
            
            // determine if the line is now too long for the line
            if calculateWidthOfText(proposedCurrentLine) > maxWidth {
                // line is too long
                
                if numberOfWordsInProposedCurrentLine == 1 {
                    // truncate the word by using ellipses
                    proposedCurrentLine = truncateText(proposedCurrentLine, toWidth: maxWidth, withEllipses: true)

                    // remove the leading text we just copied from the remainingText variable
                    remainingText.removeFirst(nextWord.count)
                } else {
                    // remove the word we just added
                    proposedCurrentLine = currentLine
                    numberOfWordsInProposedCurrentLine -= 1
                }
                
                finishCurrentLineAndStartNewLine = true
            } else {
                // line still fits; keep the proposed changes (and keep adding words, unless it was followed by the newline character)
                currentLine = proposedCurrentLine
                numberOfWordsInCurrentLine = numberOfWordsInProposedCurrentLine
                
                // remove the leading text we just copied from the remainingText variable
                remainingText.removeFirst(nextWord.count)
                if whitespaceCharacter != nil {
                    remainingText.removeFirst()
                }
                
                // if the word was followed by \n, create a new line
                if wordIsFollowedByNewline == true {
                    finishCurrentLineAndStartNewLine = true
                }
            }
            
            if finishCurrentLineAndStartNewLine == true {
                // append the current line to 'lines' and reset the current line
                lines.append(proposedCurrentLine)
                //
                currentLine = ""
                numberOfWordsInCurrentLine = 0
            }
        }
        
        // if there was one remaining line being built, append it to our list of lines now
        if currentLine != "" && lines.count < maximumNumberOfLines {
            lines.append(currentLine)
        }
        
        // remove any leading or trailing spaces from the lines
        for index in 0..<lines.count {
            lines[index] = lines[index].trimmingCharacters(in: [" "])
        }
        
        // now measure the width of each line and the combined line height
        var pixelWidth: CGFloat = 0
        var pixelHeight: CGFloat = 0
        
        for index in 0..<lines.count {
            let line = lines[index]
            let linePixelSize = calculateSizeOfText(line)
            
            if (maxHeight != nil) && (pixelHeight + linePixelSize.height > maxHeight!) {
                // line will not fit; remove it and all further lines and exit
                lines.removeLast(lines.count - index)
                break
            }

            pixelWidth = max(pixelWidth, linePixelSize.width)
            if index > 0 {
                // add a bit of vertical space between each line
                pixelHeight += titleVerticalLineSpacing
            }
            pixelHeight = pixelHeight + linePixelSize.height
        }
        
        return (pixelWidth: pixelWidth, pixelHeight: pixelHeight, lines: lines)
    }
    
    private func truncateText(_ text: String, toWidth maxWidth: CGFloat, withEllipses: Bool) -> String {
        // if the text already fits, return it as-is
        if calculateWidthOfText(text) <= maxWidth {
            return text
        }
        
        for currentLength in stride(from: text.count, to: 0, by: -1) {
            let endIndex = text.index(text.startIndex, offsetBy: currentLength)
            var proposedText = String(text[text.startIndex..<endIndex])
            if withEllipses == true {
                proposedText += "..."
            }
            
            if calculateWidthOfText(proposedText) <= maxWidth {
                return proposedText
            }
        }
        
        // if we could not fit any text, return the minimal text (empty or ellipses)
        return (withEllipses == true) ? "..." : ""
    }
    
    private func calculateSizeOfText(_ text: String) -> CGSize {
        // get size of our text (using its attributed font attributes)
        let textAsNSString = text as NSString
        let textSize = textAsNSString.size(withAttributes: [ NSAttributedString.Key.font: self.font as Any ])
        
        return textSize
    }
    
    private func calculateWidthOfText(_ text: String) -> CGFloat {
        let textSize = calculateSizeOfText(text)

        return textSize.width
    }

    private func calculateMaximumTextHeight() -> CGFloat? {
        let orientation = self.morphicBarView?.orientation ?? .horizontal

        if orientation == .horizontal {
            // we will let the text flow closer to the top/bottom edges than the full padding requires (using "top" padding which is technically the icon-to-text padding); ideally our caller would set the padding and we would use exact numbers instead
            return self.fixedHeightInHorizontalBar - self.titleTopPadding * 2
        } else {
            return nil
        }
    }
    
    private func calculateTitleTextBounds() -> NSRect {
        let orientation = self.morphicBarView?.orientation ?? .horizontal

        // get the size of our frame
        let frameSize = self.frame.size

        let (titleTextPixelWidth, titleTextPixelHeight, _) = measureAndSplitText(title, maxWidth: self.maximumWidth, maxHeight: self.calculateMaximumTextHeight())
        //
        let titleTextPosX = (frameSize.width - titleTextPixelWidth) / 2.0
        let titleTextPosY: CGFloat
        if orientation == .horizontal {
            titleTextPosY = (self.frame.height - titleTextPixelHeight) / 2
        } else /* if orientation == .vertical */ {
            titleTextPosY = self.frame.height - titleTextPixelHeight - self.titleBottomPadding
        }
        
        let titleTextBounds = NSRect(x: titleTextPosX, y: titleTextPosY, width: titleTextPixelWidth, height: titleTextPixelHeight)
        
        return titleTextBounds
    }
        
    private func calculateImageFrameSizeForPdf(pdfBounds: NSRect, maxWidth: CGFloat, maxHeight: CGFloat) -> NSSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        if pdfBounds.width > pdfBounds.height {
            width = maxWidth
            height = maxHeight * (pdfBounds.height / pdfBounds.width)
        } else {
            height = maxHeight
            width = maxWidth * (pdfBounds.width / pdfBounds.height)
        }
        
        // if one of our values still doesn't fit (i.e. because we're not using a square box), scale even smaller
        if width > maxWidth {
            let shrinkRatio = maxWidth / width
            width = width * shrinkRatio
            height = height * shrinkRatio
        }
        if height > maxHeight {
            let shrinkRatio = maxHeight / height
            width = width * shrinkRatio
            height = height * shrinkRatio
        }
        
        return NSSize(width: width, height: height)
    }
    
    // MARK: self-sizing hints to layout engine
    
    override var intrinsicContentSize: NSSize {
        get {
            let orientation = self.morphicBarView?.orientation ?? .horizontal

            var width: CGFloat = 0
            var height: CGFloat = 0

            let (titleTextPixelWidth, titleTextPixelHeight, _) = measureAndSplitText(title, maxWidth: self.maximumWidth, maxHeight: self.calculateMaximumTextHeight())

            width += titleTextPixelWidth
        
            height += titleTextPixelHeight
            //
            height += self.titleBottomPadding
            //
            if icon != nil {
                height += self.titleTopPadding
                //
                let minimumFrameWidthForIcon = CGFloat(100.0);
                let iconCircleDiameter = calculateIconCircleDiameter(usingFrameWidth: max(width, minimumFrameWidthForIcon))
                height += iconCircleDiameter
                width = max(width, iconCircleDiameter)
            } else {
                // if there is no icon, mirror the title's bottom padding on top (since the "top padding" is really the icon-to-text vertical padding)
                height += self.titleBottomPadding
            }
            
            width += self.titleLeftAndRightPadding * 2
            
            if orientation == .horizontal {
                // for horizontal bars, make the buttons full-height
                height = self.fixedHeightInHorizontalBar
            } else if orientation == .vertical {
                // for vertical bars, make the buttons full-width
                width = max(width, self.maximumWidth)
            }

            return NSSize(width: width, height: height)
        }
    }
    
    override func layout() {
        configureTitleBoxLayer()
        configureIconCircleLayer()
        configureIconImageLayer()
        configureTitleTextLayer()
    }

    // MARK: utils
    
    private func backingScaleFactor() -> CGFloat? {
        // select the current window's scale factor (e.g. Retina vs. non-Retina); as a backup use the "single-monitor" scale factor
        if let backingScaleFactor = window?.backingScaleFactor {
            return backingScaleFactor
        } else if let backingScaleFactor = NSScreen.main?.backingScaleFactor {
            return backingScaleFactor
        }
        
        return nil
    }
    
    // MARK: properties
    
    public var backgroundColor: NSColor? = nil {
        didSet {
            self.needsDisplay = true
        }
    }
    
    public var fillColor: NSColor = NSColor(red: 0/255.0, green: 41/255.0, blue: 87/255.0, alpha: 1.0) {
        didSet {
            configureTitleBoxLayer()
            configureIconCircleLayer()
            if iconColor == nil {
                configureIconImageLayer()
            }
        }
    }
    
    override var font: NSFont? {
        didSet {
            configureTitleTextLayer()
        }
    }
    
    var fontColor: NSColor? {
        didSet {
            configureTitleTextLayer()
        }
    }

    public var icon: MorphicBarButtonItemIcon? {
        didSet {
            configureIconCircleLayer()
            configureIconImageLayer()
            configureTitleBoxLayer()
            configureTitleTextLayer()
        }
    }
    
    public var iconColor: NSColor? {
        didSet {
            configureIconImageLayer()
        }
    }
    
    public var iconCircleStrokeWidth: CGFloat = 2.0 {
        didSet {
            configureIconCircleLayer()
        }
    }
    
    public var roundedRectangeCornerRadius: CGFloat = 10.0 {
        didSet {
            configureTitleBoxLayer()
            self.needsLayout = true
        }
    }

    override var title: String {
        didSet {
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }
    
    public var titleBottomPadding: CGFloat = 10.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }

    public var titleTopPadding: CGFloat = 3.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }
    
    public var titleLeftAndRightPadding: CGFloat = 10.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }
    
    public var titleVerticalLineSpacing: CGFloat = 2.0 {
        didSet {
            configureTitleBoxLayer()
            configureTitleTextLayer()
            self.needsLayout = true
        }
    }
    
    override func becomeFirstResponder() -> Bool {
    	// alert the MorphicBarWindow that we have gained focus
        morphicBarView?.childViewBecomeFirstResponder(sender: self)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
    	// alert the MorphicBarWindow that we have lost focus
        morphicBarView?.childViewResignFirstResponder()
        return super.resignFirstResponder()
    }
}
