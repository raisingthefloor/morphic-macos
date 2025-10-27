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

// NOTE: this is a partially-reverse-engineered header (i.e. not the complete original header)
//
// Tools: nm; Ghidra; RuntimeBrowser; Hopper Disassembler v4; manual analysis
// Path: /System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness
// OS: macOS 10.15.7

#import <Foundation/Foundation.h>

@interface CBBlueLightClient : NSObject

typedef struct {
    int hour;
    int minute;
} CBBlueLight_ScheduleTime;

typedef struct {
    CBBlueLight_ScheduleTime from;
    CBBlueLight_ScheduleTime to;
} CBBlueLight_Schedule;

typedef struct {
    BOOL active;
    BOOL enabled;
    BOOL locationPermissionGranted;
    int mode;
    CBBlueLight_Schedule schedule;
    unsigned long long unknown1;
    BOOL unknown2;
} CBBlueLight_Status;

- (BOOL)getBlueLightStatus:(CBBlueLight_Status *)status;
- (BOOL)getStrength:(float*)strength;
- (BOOL)setActive:(BOOL)active;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)setMode:(int)mode;
- (BOOL)setSchedule:(const CBBlueLight_Schedule*)schedule;
// NOTE: a Hopper header file export provided us with an unknown block signature; the first argument appears to be in the format of CBBlueLight_Status, so we're using that; in the future if we have any problems we could alternatively use the "empty block signature" (below, from Hopper) and call getBlueLightStatus instead.  Note that there may be additional arguments passed in the callback; more research (presumably Ghidra or Hopper) would be needed to determine further details
//- (void)setStatusNotificationBlock:(void (^ /* unknown block signature */)(void))v1;
// NOTE: in our brief Ghidra analysis, it appears that setting statusNotificationBlock to nil suspends notifications (and setting it to non-nil enables them)
- (void)setStatusNotificationBlock:(void(^)(CBBlueLight_Status* pointerToStatus))statusNotificationBlock;
- (BOOL)setStrength:(float)strength commit:(BOOL)commit;

@end
