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

/// A custom NSTextField subclass that always adds shadow attributes to the displayed text
public class ShadowedLabel: NSTextField {
    
    /// The color of the text shadow to add
    @IBInspectable public var textShadowColor: NSColor = .black
    
    /// The offset of the text shadow to add
    @IBInspectable public var textShadowOffset: CGSize = NSSize(width: 1, height: 2)
    
    /// The blur radius of the text shadow to add
    @IBInspectable public var textShadowBlurRadius: CGFloat = 0
    
    /// The shadow created from the other `textShadow*` properties
    ///
    /// - note: The other properties are split out so they can be individually `IBInspectable`
    public var textShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = textShadowColor
        shadow.shadowOffset = textShadowOffset
        shadow.shadowBlurRadius = textShadowBlurRadius
        return shadow
    }
    
    public override var stringValue: String {
        get {
            return super.stringValue
        }
        set {
            super.stringValue = newValue
            // take whatever atttributed string NSTextField creates in its base implementation
            // and add the attribute that makes a text shadow.  This method ensures we don't lose any
            // attribute that NSTextField adds to the attributed string
            let attributedValue = NSMutableAttributedString(attributedString: attributedStringValue)
            attributedValue.addAttributes([.shadow: textShadow], range: NSRange(location: 0, length: newValue.count))
            attributedStringValue = attributedValue
        }
    }
    
    public override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        // Pad the intrinsic content size so the text shadow isn't cut off
        size.height += 4
        return size
    }
    
}
