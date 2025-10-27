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

// NOTE: this header is reverse-engineered
// Tools: Ghidra; Hopper Disassembler v4; manual analysis
// Path: /System/Library/PrivateFrameworks/SkyLight.framework/SkyLight
// OS: macOS 10.15.7

/* process to discover the functions used to set/get appearance:
 * 1. Run Hopper Disassembler v4 on /System/Library/PreferencePanes/Appearance.prefPane/Contents/MacOS/Appearance
 * 2. We found the "setTheme" function which appears to call out to SLSSetAppearanceThemeLegacy with a 1 or 0 to set dark vs. light theme
 * 3. Run "mdfind" on files inside /System/Library/PrivateFrameworks to search for "SLSSetAppearanceThemeLegacy"
 * 4. Ghidra can extract the parameters and return type for SLSSetAppearanceThemeLegacy; we also found SLSGetAppearanceThemeLegacy (simply by switching the word "Get" for "Set" and then reading out its function signature
 */

void SLSSetAppearanceThemeLegacy(uint8_t arg0);
uint64_t SLSGetAppearanceThemeLegacy();
//
void SLSSetAppearanceThemeSwitchesAutomatically(uint32_t arg0);
uint64_t SLSGetAppearanceThemeSwitchesAutomatically();
