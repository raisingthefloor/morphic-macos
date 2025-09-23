// Copyright 2020-2021 Raising the Floor - US, Inc.
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

class PermissionsSuccessWindowController: NSWindowController, PermissionsWindowController {
    @IBOutlet weak var guideBox: NSBox!
    @IBOutlet weak var firstLine: NSTextFieldCell!
    @IBOutlet weak var secondLine: NSTextFieldCell!
    @IBOutlet weak var iconImg: NSImageCell!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // draw the window as a fully-opaque overlay over the System Preferences window
        window?.isOpaque = false
        window?.backgroundColor = NSColor.clear
	
        // NOTE: ideally we should color the guideBox a little bit differently (or a bit darker) or otherwise emphasize i.
        guideBox.fillColor = NSColor.windowBackgroundColor
        
        // float the window (so that it appears over System Preferences)
        window?.level = .floating
        
        // turn off accessibility elements for the entire window and its ocntents
        window?.setAccessibilityElement(false)
        //
        guideBox.setAccessibilityElement(false)
        firstLine.setAccessibilityElement(false)
        secondLine.setAccessibilityElement(false)
        iconImg.setAccessibilityElement(false)
        
        // hide the window by default
        window?.setIsVisible(false)
    }
}
