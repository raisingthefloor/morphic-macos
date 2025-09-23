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
import MorphicSettings
import MorphicService

protocol CreateAccountViewControllerDelegate: class {
    
    func createAccount(_ viewController: CreateAccountViewController, didCreate user: User)

}

class CreateAccountViewController: NSViewController, NSTextFieldDelegate, PresentedPageViewController {
    
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var confirmPasswordField: NSSecureTextField!
    @IBOutlet weak var submitButton: NSButton!
    
    var preferences: Preferences!
    
    weak var delegate: CreateAccountViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func pageTransitionCompleted() {
        view.window?.makeFirstResponder(emailField)
    }
    
    // NOTE: this function handles the enter key (submitting the registration info if the user has already entered an email address and matching passwords)
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if control == self.emailField || control == self.passwordField || control == self.confirmPasswordField {
            // handle the enter key
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if (self.submitButton.isEnabled == true) {
                    DispatchQueue.main.async {
                        self.submitButton.becomeFirstResponder()
                        self.createAccount(self.submitButton)
                    }
                }
                
                // return true if the action was handled
                return true
            }
        }
        
        // return false if the action was not handled
        return false
    }

    @IBAction
    func createAccount(_ sender: Any?) {
        hideError()
        setFieldsEnabled(false)
        var user = User(identifier: "")
        user.email = emailField.stringValue.trimmingCharacters(in: .whitespaces)
        let creds = UsernameCredentials(username: user.email!, password: passwordField.stringValue)
        Session.shared.register(user: user, credentials: creds, preferences: preferences) {
            result in
            switch result {
            case .success(let auth):
                DistributedNotificationCenter.default().postNotificationName(.morphicSignin, object: nil, userInfo: ["isRegister": true], deliverImmediately: true)
                self.delegate?.createAccount(self, didCreate: auth.user)
            case .badPassword:
                self.showError(message: "Password too short or easily guessed", pointingTo: self.passwordField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.passwordField)
                self.hasTypedBothPasswords = false
                self.confirmPasswordField.stringValue = ""
            case .existingEmail:
                self.showError(message: "This email already has an account", pointingTo: self.emailField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            case .invalidEmail:
                self.showError(message: "Must be an email address", pointingTo: self.emailField)
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            case .error:
                let alert = NSAlert()
                alert.messageText = "Account Creation Failed"
                alert.informativeText = "Sorry we couldn't create your account right now.  Please try again."
                alert.runModal()
                self.setFieldsEnabled(true)
                self.view.window?.makeFirstResponder(self.emailField)
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateValid()
        guard let field = obj.object as? NSTextField else {
            return
        }
        if (field == passwordField || field == confirmPasswordField) {
            if hasTypedBothPasswords{
                updatePasswordMatch()
            }
        }
    }
    
    @IBOutlet weak var errorPopover: NSPopover!
    var hasTypedBothPasswords = false
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else{
            return
        }
        if field == passwordField || field == confirmPasswordField {
            if passwordField.stringValue.count > 0 && confirmPasswordField.stringValue.count > 0 {
                hasTypedBothPasswords = true
                updatePasswordMatch()
            }
        }
    }
    
    func updatePasswordMatch() {
        if passwordField.stringValue.count > 0 && confirmPasswordField.stringValue.count > 0 && passwordField.stringValue != confirmPasswordField.stringValue{
            showError(message: "Passwords do not match", pointingTo: confirmPasswordField)
        } else {
            hideError()
        }
    }
    
    func updateValid() {
        submitButton.isEnabled = emailField.stringValue.trimmingCharacters(in: .whitespaces).count > 0 && passwordField.stringValue.count > 0 && passwordField.stringValue == confirmPasswordField.stringValue
    }
    
    func setFieldsEnabled(_ enabled: Bool) {
        emailField.isEnabled = enabled
        passwordField.isEnabled = enabled
        confirmPasswordField.isEnabled = enabled
        submitButton.isEnabled = enabled
    }
    
    @IBOutlet var errorViewController: CreateAccountErrorViewController!
    
    func showError(message: String, pointingTo view: NSView) {
        errorViewController.errorText = message
        errorPopover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxX)
    }
    
    func hideError() {
        if errorPopover.isShown{
            errorPopover.close()
        }
    }
    
}

class CreateAccountErrorViewController: NSViewController {
    
    @IBOutlet weak var errorLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.stringValue = errorText ?? ""
    }
    
    var errorText: String? {
        didSet {
            errorLabel?.stringValue = errorText ?? ""
        }
    }
    
}
