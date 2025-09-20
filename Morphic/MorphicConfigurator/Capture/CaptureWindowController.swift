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
import MorphicCore
import MorphicService

class CaptureWindowController: NSWindowController, CaptureViewControllerDelegate, CreateAccountViewControllerDelegate {
    
    var pageViewController = PageViewController(nibName: "PageViewController", bundle: nil)

    override func windowDidLoad() {
        super.windowDidLoad()
//        window?.backgroundColor = NSColor(named: "WindowBackgroundColor")
        window?.contentViewController = pageViewController
        showCapture(animated: false)
    }
    
    func showCapture(animated: Bool) {
        let captureViewController = CaptureViewController(nibName: "CaptureViewController", bundle: nil)
        captureViewController.delegate = self
        pageViewController.show(viewController: captureViewController, animated: animated)
    }
    
    func capture(_ viewController: CaptureViewController, didCapture preferences: Preferences) {
        if Session.shared.user == nil {
            showCreateAccount(preferences: preferences, animated: true)
        } else {
            showDone(animated: true)
        }
    }
    
    func showCreateAccount(preferences: Preferences, animated: Bool) {
        let createAccountViewController = CreateAccountViewController(nibName: "CreateAccountViewController", bundle: nil)
        createAccountViewController.preferences = preferences
        createAccountViewController.delegate = self
        pageViewController.show(viewController: createAccountViewController, animated: animated)
    }
    
    func createAccount(_ viewController: CreateAccountViewController, didCreate user: User) {
        showDone(animated: true)
    }
    
    func showDone(animated: Bool) {
        let doneViewController = DoneViewController(nibName: "DoneViewController", bundle: nil)
        pageViewController.show(viewController: doneViewController, animated: animated)
    }

}
