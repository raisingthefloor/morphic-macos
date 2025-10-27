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

class QuickHelpStepViewController: NSViewController {
    
    /// The label that displays the help title
    @IBOutlet weak var titleLabel: NSTextField!
    
    /// The label that displays the detailed help message
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var pageControl: PageControl!
    
    var percentageFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = CGColor(gray: 0, alpha: 1.0)
        view.layer?.cornerRadius = 6
        percentageFormatter.numberStyle = .percent
        updateTitleLabel()
        updateMessageLabel()
        updateStep()
    }
    
    /// The text to display in the title label
    public var titleText: String = "" {
        didSet{
            updateTitleLabel()
        }
    }
    
    public func updateTitleLabel() {
        titleLabel?.stringValue = titleText
    }
    
    /// The text to display in the message label
    public var messageText: String = "" {
        didSet {
            updateMessageLabel()
        }
    }
    
    public func updateMessageLabel() {
        messageLabel?.stringValue = messageText
    }
    
    public var numberOfSteps: Int = 1 {
        didSet {
            updateStep()
        }
    }
    
    public var step: Int = 0 {
        didSet {
            updateStep()
        }
    }
    
    public func updateStep() {
        pageControl?.numberOfPages = numberOfSteps
        pageControl?.selectedPage = step
    }
    
}
