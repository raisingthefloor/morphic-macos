// Copyright 2020-2025 Raising the Floor - US, Inc.
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

class AboutBoxWindowController: NSWindowController, NSWindowDelegate {

    private static var singleWindowController: AboutBoxWindowController?
    
    @IBOutlet weak var versionTextField: NSTextField!
    @IBOutlet weak var buildTextField: NSTextField!

    @IBOutlet weak var copyrightTextField: NSTextField!

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("AboutBoxWindowController")
    }
    
    //

    static var single: AboutBoxWindowController {
        if let singleWindowController = self.singleWindowController {
            return singleWindowController
        } else {
            let aboutBoxWindowController = AboutBoxWindowController()
            aboutBoxWindowController.window?.delegate = aboutBoxWindowController
            //
            AboutBoxWindowController.singleWindowController = aboutBoxWindowController
            return aboutBoxWindowController
        }
    }

    func windowWillClose(_ notification: Notification) {
        AboutBoxWindowController.singleWindowController = nil
    }

    //
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // populate the version and build # in our labels
        if let shortVersionAsString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionTextField.stringValue = "version " + shortVersionAsString
        } else {
            self.versionTextField.stringValue = "[version is unknown]"
        }
        //
        if let buildAsString = Bundle.main.infoDictionary?["CFBundleVersion" as String] {
            self.buildTextField.stringValue = "(build \(buildAsString))"
        } else {
            self.buildTextField.stringValue = "[build version is unknown]"
        }
        
        self.copyrightTextField.stringValue = "Copyright (c) 2020-2025 Raising the Floor - US Inc."
    }
    
    func centerOnScreen() {
        guard let screenFrame = NSScreen.main?.frame else {
            return
        }
        guard let windowFrame = self.window?.frame else {
            return
        }
        
        let newOrigin = NSPoint(x: (screenFrame.width - windowFrame.width) / 2, y: (screenFrame.height - windowFrame.height) / 2)
        self.window?.setFrameOrigin(newOrigin)
    }
}
