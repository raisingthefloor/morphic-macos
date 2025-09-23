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

// NOTE: as our dock app doesn't have a menu (and we want to manually create that menu if we're going to support it), we use main.swift to startup instead of MainMenu.xib+AppDelegate.

// create a strong reference to a new application delegate
let applicationDelegate = AppDelegate()
//
// set our application's delegate
NSApplication.shared.delegate = applicationDelegate
//
// launch our application (starting up the application delegate) using optionally-provided command-line arguments
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
