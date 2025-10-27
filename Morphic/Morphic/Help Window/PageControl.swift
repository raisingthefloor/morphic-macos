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

class PageControl: NSView {
    
    public var numberOfPages: Int = 1 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay(bounds)
        }
    }
    
    public var selectedPage: Int = -1 {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    @IBInspectable
    public var dotColor: NSColor = .white {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    public var dotSize: CGFloat {
        bounds.height
    }
    
    public var dotSpacing: CGFloat {
        dotSize
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: CGFloat(numberOfPages) * dotSize + CGFloat(numberOfPages - 1) * dotSpacing, height: NSView.noIntrinsicMetric)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else{
            return
        }
        context.saveGState()
        context.setFillColor(dotColor.cgColor)
        context.setStrokeColor(dotColor.cgColor)
        context.setLineWidth(1.0)
        var x: CGFloat = 0
        for i in 0..<numberOfPages {
            let rect = CGRect(x: x, y: 0, width: dotSize, height: dotSize)
            if i == selectedPage {
                context.fillEllipse(in: rect)
            }else{
                context.strokeEllipse(in: rect)
            }
            x += dotSize + dotSpacing
        }
        context.restoreGState()
    }
    
}
