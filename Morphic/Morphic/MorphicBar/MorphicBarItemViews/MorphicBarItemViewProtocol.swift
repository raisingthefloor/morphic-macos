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

public protocol MorphicBarItemViewProtocol: NSView {
    // NOTE: this protocol field must be implemented as follows by default:
    // var showsHelp: Bool = true
    var showsHelp: Bool { get set }
    
    // NOTE: the following must also be implemented in all classes conforming to MorphicBarItemViewProtocol
    // public override var isFlipped: Bool { return true }
    var isFlipped: Bool { get }

    // NOTE: the protocol field must be implemented as WEAK:
    // public weak var morphicBarView: MorphicBarView?
    var morphicBarView: MorphicBarView? { get set }
    
    var contentFrames: [CGRect] { get }
}

// NOTE: this delegate is used to bubble up "child focus/lostfocus" style of events to the window/view (so it can handle logic around keyboard accessibility focus)
public protocol MorphicBarWindowChildViewDelegate {
    func childViewBecomeFirstResponder(sender: NSView)
    func childViewResignFirstResponder()
}
