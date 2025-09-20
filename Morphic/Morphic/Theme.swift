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

/// A green from the dark end of the gradient in the Morphic logo
private var darkerGreen = NSColor(srgbRed: 0, green: 129.0/255.0, blue: 69.0/255.0, alpha: 1.0)

/// A green from the middle of the gradient in the Morphic logo
private var lighterGreen = NSColor(srgbRed: 102.0/255.0, green: 181.0/255.0, blue: 90.0/255.0, alpha: 1.0)

/// The same dark blue found around the oustside of the Morphic logo
private var darkBlue = NSColor(srgbRed: 0, green: 41.0/255.0, blue: 87.0/255.0, alpha: 1.0)

extension NSColor {
    
    /// The primary dark color to use for Morphic elements
    ///
    /// Suitable to use with a light or white foreground color
    static var morphicPrimaryColor = darkerGreen
    
    /// A slightly lighter version of the `morphicPrimaryColor`
    ///
    /// Suitable to use with a light or white foreground color
    static var morphicPrimaryColorLightend = lighterGreen
    
    /// An alternative dark color to use for Morphic elements
    ///
    /// Distinct from the `morphicPrimaryColor`.  Suitable to use with a light or white foreground color.
    static var morphicAlternateColor = darkBlue
    
}

extension NSFont {
    
    static var morphicRegular: NSFont = .systemFont(ofSize: 14.0, weight: .regular)
    static var morphicBold : NSFont = .systemFont(ofSize: 14.0, weight: .bold)
    static var morphicHeavyForPlusMinusSymbols: NSFont = .systemFont(ofSize: 22, weight: .heavy)
}
