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

class ProgressIndicator: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.borderWidth = borderWidth
        layer?.borderColor = borderColor.cgColor
        layer?.cornerRadius = bounds.height / 2.0
        barLayer.backgroundColor = barColor.cgColor
        layer?.addSublayer(barLayer)
        updateBar()
    }
    
    private var barLayer = CALayer()
    
    @IBInspectable
    public var barColor: NSColor = .white {
        didSet {
            barLayer.backgroundColor = barColor.cgColor
            setNeedsDisplay(bounds)
        }
    }
    
    @IBInspectable
    public var borderColor: NSColor = .white {
        didSet {
            layer?.borderColor = borderColor.cgColor
        }
    }
    
    public var borderWidth: CGFloat = 1.0 {
        didSet {
            layer?.borderWidth = borderWidth
        }
    }
    
    public var doubleValue: Double = 0.0 {
        didSet {
            updateBar()
        }
    }
    
    func updateBar() {
        barLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * CGFloat(doubleValue), height: bounds.height)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layer?.cornerRadius = bounds.height / 2.0
        updateBar()
    }
    
}
