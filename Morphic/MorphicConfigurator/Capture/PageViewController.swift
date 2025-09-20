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

class PageViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func show(viewController: NSViewController, animated: Bool) {
        let shown = children.first
        shown?.removeFromParent()
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        let completion = {
            shown?.view.removeFromSuperview()
            if let presentedViewController = viewController as? PresentedPageViewController {
                presentedViewController.pageTransitionCompleted()
            }
        }
        if animated {
            let dismissing = shown?.view
            let presenting = viewController.view
            presenting.frame = NSRect(origin: NSPoint(x: self.view.bounds.width, y: 0), size: view.bounds.size)
            NSAnimationContext.runAnimationGroup({
                context in
                context.duration = 0.4
                presenting.animator().frame = NSRect(origin: .zero, size: self.view.bounds.size)
                dismissing?.animator().frame = NSRect(origin: NSPoint(x: -self.view.bounds.width, y: 0), size: self.view.bounds.size)
                dismissing?.animator().alphaValue = 0.0
            }, completionHandler: completion)
        } else {
            completion()
        }
    }
    
}

protocol PresentedPageViewController {
    
    func pageTransitionCompleted()
    
}
