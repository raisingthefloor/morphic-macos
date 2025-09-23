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
// Path: /System/Library/PrivateFrameworks/UniversalAccess.framework/UniversalAccess
// OS: macOS 10.15.7

// NOTE: to date, we have been unable to set the "invert colors" setting due to insufficient permissions (or bundle ID missing/mismatch, etc.)
void UAInvertColorsUserInitiatedSetEnabled(int arg0);
int UAWhiteOnBlackIsEnabled();

/* ./Frameworks/UniversalAccessCore */
int UAGrayscaleSynchronizeLegacyPref();
int UAIncreaseContrastIsEnabled();
void UAIncreaseContrastSetEnabled(int arg0);
