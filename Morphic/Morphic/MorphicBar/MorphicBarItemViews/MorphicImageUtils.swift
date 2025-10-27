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

class MorphicImageUtils {
    // MARK: B&W image recoloring

    static func colorImage(_ image: NSImage, withColor tintColor: NSColor) -> NSImage {
        // calculate the bounds of our image
        let imageBounds = NSRect(origin: .zero, size: image.size)

        // create an opaque copy of the provided tint color; we will lower the opacity of our image to preserve the color opacity
        let opaqueTintColor = tintColor.withAlphaComponent(1)

        // create a copy of the original image (but at the alpha level specified by our color)
        // NOTE: we create the image copy at the alpha level of our tint color so that we can then flood it with a color with 100% opacity
        //
        // first create the empty image
        let copyOfImage = NSImage(size: image.size)
        let copyOfImageBounds = NSRect(origin: .zero, size: copyOfImage.size)
        //
        // prepare our new image to receive drawing commands
        copyOfImage.lockFocus()
        //
        // draw a copy of our image (at the alpha level of our tintColor) into the new image
        image.draw(in: copyOfImageBounds, from: imageBounds, operation: .sourceOver, fraction: tintColor.alphaComponent)

        // choose the provided tintColor (but using 100% opacity) to tint our image
        opaqueTintColor.set()
        // tint (recolor) our image
        copyOfImageBounds.fill(using: .sourceAtop)

        // remove the focus from our image (as we are done drawing)
        copyOfImage.unlockFocus()

        return copyOfImage
    }
}
