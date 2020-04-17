// Copyright 2020 Raising the Floor - International
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

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        createUserButton.isHidden = UserDefaults.morphic.string(forKey: .morphicDefaultsKeyUserIdentifier) != nil
        clearUserButton.isHidden = !createUserButton.isHidden
        
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    @IBOutlet weak var createUserButton: NSButton!
    @IBOutlet weak var clearUserButton: NSButton!
    
    @IBAction
    func createTestUser(_ sender: Any){
        createUserButton.isEnabled = false
        Session.shared.registerUser(){
            success in
            if success{
                NSApplication.shared.terminate(sender)
            }else{
                self.createUserButton.isEnabled = true
            }
        }
    }
    
    @IBAction
    func clearUser(_ sender: Any){
        Session.shared.signout()
        NSApplication.shared.terminate(sender)
    }


}
