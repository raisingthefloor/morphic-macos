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

protocol CaptureViewControllerDelegate: class {
    
    func capture(_ viewController: CaptureViewController, didCapture preferences: Preferences)

}

class CaptureViewController: NSViewController {
    
    @IBOutlet weak var gearImage: NSImageView!
    
    weak var delegate: CaptureViewControllerDelegate?
    
    var captureSession: CaptureSession!
    
    var minimumTimeInterval: TimeInterval = 3
    var minimumTimer: Timer?
    
    var captureComplete = false
    var miniumTimeComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let preferences = Session.shared.preferences ?? Preferences(identifier: "")
        captureSession = CaptureSession(settingsManager: Session.shared.settings, preferences: preferences)
        captureSession.addAllSolutions()
        captureSession.captureDefaultValues = false
        captureSession.run {
            self.captureComplete = true
            self.notifyDelegateIfFullyComplete()
        }
        DispatchQueue.main.async {
            self.minimumTimer = Timer.scheduledTimer(withTimeInterval: self.minimumTimeInterval, repeats: false) {
                _ in
                self.miniumTimeComplete = true
                self.notifyDelegateIfFullyComplete()
            }
        }
    }
    
    func notifyDelegateIfFullyComplete() {
        guard miniumTimeComplete && captureComplete else{
            return
        }
        stopAnimating()
        delegate?.capture(self, didCapture: captureSession.preferences)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        startAnimating()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopAnimating()
    }
    
    var animation: CABasicAnimation!
    
    func startAnimating() {
        animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = -CGFloat.pi * 2
        animation.repeatCount = .infinity
        animation.duration = 7
        gearImage.layer?.add(animation, forKey: "spin")
    }
    
    func stopAnimating() {
        gearImage.layer?.removeAnimation(forKey: "spin")
        animation = nil
    }
    
}

class ImageContainerView: NSView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        needsLayout = true
    }
    
    override func layout() {
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        for view in subviews{
            view.layer?.bounds = CGRect(origin: .zero, size: bounds.size)
            view.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view.layer?.position = center
        }
    }
    
}
