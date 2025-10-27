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
import MorphicMacOSNative
import MorphicSettings

class UpdateAvailableWindow: NSWindowController, URLSessionTaskDelegate, URLSessionDownloadDelegate {

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("UpdateAvailableWindow")
    }
    
    @IBOutlet weak var currentVersionLabel: NSTextField!
    @IBOutlet weak var updatedVersionLabel: NSTextField!
    
    @IBOutlet weak var downloadNowQuestionLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    @IBOutlet weak var downloadNowButton: NSButton!
    @IBOutlet weak var remindMeButton: NSButton!
    @IBOutlet weak var cancelDownloadButton: NSButton!
    
    private var downloadAppcastXmlTask: URLSessionDownloadTask?
    
    internal var currentVersionAsString: String? {
        didSet {
            self.currentVersionLabel?.stringValue = self.currentVersionAsString ?? ""
        }
    }
    internal var updatedVersionAsString: String? {
        didSet {
            self.updatedVersionLabel?.stringValue = self.updatedVersionAsString ?? ""
        }
    }
    internal var downloadUrl: URL?
    
    internal var cancelButtonWasPressed = false
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.currentVersionLabel.stringValue = self.currentVersionAsString ?? ""
        self.updatedVersionLabel.stringValue = self.updatedVersionAsString ?? ""
        
        self.downloadNowButton.becomeFirstResponder()
    }
    
    @IBAction func downloadNowPressed(_ sender: Any) {
        guard let downloadUrl = self.downloadUrl else {
            fatalError("downloadUrl must be intiailized before showing this window")
        }
        
        // change our UI to show a progress bar (and give the user a cancel button)
        self.downloadNowQuestionLabel.isHidden = true
        self.progressBar.isHidden = false
        self.progressBar.doubleValue = 0
        //
        self.downloadNowButton.isHidden = true
        self.remindMeButton.isHidden = true
        self.remindMeButton.isEnabled = false // disable, since it handles the esc key
        self.cancelDownloadButton.isHidden = false
        self.cancelDownloadButton.isEnabled = true

        let urlSessionWithProgressDelegate = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        let downloadAppcastXmlTask = urlSessionWithProgressDelegate.downloadTask(with: downloadUrl)
        self.downloadAppcastXmlTask = downloadAppcastXmlTask
        
        self.downloadAppcastXmlTask?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard downloadTask == self.downloadAppcastXmlTask else {
            return
        }
        
        DispatchQueue.main.async {
            self.progressBar.doubleValue = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100.0
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task == self.downloadAppcastXmlTask else {
            return
        }
        
        // downloaded completed, with or without error

        if cancelButtonWasPressed == true {
            // the user intentionally stopped the operation; ignore the failure
            self.closeAsync()
            return
        }
        
        guard error == nil else {
           self.showAlertAsync(messageText: "Download failed", informativeText: "Sorry, we could not download the updated software. Please try again later.")
           self.closeAsync()
           return
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard downloadTask == self.downloadAppcastXmlTask else {
            return
        }

        // download completed, without error
        let filename = self.downloadUrl!.lastPathComponent
        let moveToUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appendingPathComponent(filename)

        let fileManager = FileManager()

        // if the target file already exists, delete it
        if fileManager.fileExists(atPath: moveToUrl.path) {
            do {
                try fileManager.removeItem(at: moveToUrl)
            } catch {
                self.showAlertAsync(messageText: "Download failed", informativeText: "Sorry, a file with the same name as the downloaded installer \"\(filename)\" already exists in your Downloads folder.\n\nPlease visit morphic.org to manually download the update.")
                self.closeAsync()
                return
            }
        }

        // move the downloaded installer to "~/Downloads"
        do {
            try fileManager.moveItem(at: location, to: moveToUrl)
        } catch {
            self.showAlertAsync(messageText: "Download failed", informativeText: "Sorry, we could not move the downloaded installer \"\(filename)\" to your Downloads folder.\n\nPlease visit morphic.org to manually download the update.")
            self.closeAsync()
            return
        }

        // launch the downloaded installer
        MorphicProcess.openProcess(at: moveToUrl, arguments: [], activate: true, hide: false) {
            runningApplication, error in
            //
            guard error == nil else {
                self.showAlertAsync(messageText: "Download complete", informativeText: "Morphic has downloaded the installer \"\(filename)\" to your Downloads folder.\n\nPlease run the installer to update Morphic.")
                self.closeAsync()
                return
            }
            
            // close our "update available" window
            self.closeAsync()

            // shut down Morphic; it will be restarted once the installer has completed.
            //
            // NOTE: we supress "resetSettings" during quitting-for-update so that the settings are _not_ reset
            ConfigurableFeatures.shared.resetSettingsIsEnabled = false
            //
            // NOTE: ideally, in the future, we would instead have Morphic check the version of the currently-running
            //       software when it started up...and then instruct the old software to shut down if a newer version was
            //       starting up instead; the old version would surpress its resetSettings (reset to standard) while exiting.
            //
            DispatchQueue.main.async {
                AppDelegate.shared.quitApplication()
            }
        }
    }

    @IBAction func cancelDownloadPressed(_ sender: Any) {
        cancelButtonWasPressed = true
        downloadAppcastXmlTask?.cancel()
        self.close()
    }
    
    private func closeAsync() {
        DispatchQueue.main.async {
            self.close()
        }
    }
    
    private func showAlertAsync(messageText: String, informativeText: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = messageText
            alert.informativeText = informativeText
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }
    }
    
    @IBAction func remindMeLaterPressed(_ sender: Any) {
        self.close()
    }
}
