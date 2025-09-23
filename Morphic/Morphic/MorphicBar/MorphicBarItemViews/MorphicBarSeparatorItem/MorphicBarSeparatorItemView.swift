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

class MorphicBarSeparatorItemView: NSButton, MorphicBarItemViewProtocol {
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

    private let separatorWidthAndHeight = 10
    
    //
    
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: separatorWidthAndHeight, height: separatorWidthAndHeight))
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
        layer?.backgroundColor = .clear
    }

    private func initialize() {
        // make our view a layer-based view
        self.wantsLayer = true
        
        // remove ourselves from any potential tab order or focus
        self.refusesFirstResponder = true
    }
    
    // MARK: self-sizing hints to layout engine
    
    override var intrinsicContentSize: NSSize {
        get {
            let width: CGFloat = CGFloat(separatorWidthAndHeight)
            let height: CGFloat = CGFloat(20)
            
            return NSSize(width: width, height: height)
        }
    }
}
