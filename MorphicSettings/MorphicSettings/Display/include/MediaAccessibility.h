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
// Path: /System/Library/Frameworks/MediaAccessibility.framework/MediaAccessibility
// OS: macOS 10.15.7

/* process to discover the functions used to set/get 'color filter enabled':
 * 1. Run Hopper Disassembler v4 on /System/Library/PreferencePanes/UniversalAccessPref.prefPane/Contents/MacOS/UniversalAccessPref
 * 2. We found the "toggleDisplayFiltersEnabled" function which appears to call out to MADisplayFilterPrefSetCategoryEnabled with a 1 or 0 to enable/disable color filters; it then calls self.updateInvertColorToBeMutuallyExclusiveWithDisplayFilter and then  UAGrayscaleSynchronizeLegacyPref().
 * 3. We realized that MADisplayFilterCategoryEnabled is a flag set in the com.apple.mediaaccessibility.plist file when the setting is enabled/disabled, so we searched for MediaAccessibility.framework and found it in /System/Library/Frameworks
 * 4. Ghidra can extract the parameters and return type for MADisplayFilterPrefSetCategoryEnabled; we also found MADisplayFilterPrefGetCategoryEnabled (simply by switching the word "Get" for "Set" and then reading out its function signature
 */

int MADisplayFilterPrefGetCategoryEnabled(int arg0 /* presumably index or display id */);
void MADisplayFilterPrefSetCategoryEnabled(int arg0 /* presumably index or display id */, int arg1 /* enabled state */);
