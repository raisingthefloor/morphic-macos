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

class HyperlinkTextField: NSTextField {
    @IBInspectable
    var urlAsString: String? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // clear out our current tracking areas
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        // add a new tracking area equal to our bounds (and capturing our mouseEntered and mouseExited events)
        let newTrackingArea = NSTrackingArea(rect: self.bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(newTrackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        NSCursor.arrow.set()
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if let urlAsString = self.urlAsString {
            if let url = URL(string: urlAsString) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
