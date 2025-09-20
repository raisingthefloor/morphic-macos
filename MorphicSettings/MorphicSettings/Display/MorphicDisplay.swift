// Copyright 2020-2022 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
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
import ColorSync

// NOTE: the MorphicDisplay class contains the functionality used by Obj-C and Swift applications

public class MorphicDisplay {

    // MARK: - DisplayMode struct
    
    public struct DisplayMode: Equatable {
        public let ioDisplayModeId: Int32 
        public let widthInPixels: Int
        public let heightInPixels: Int
        public let widthInVirtualPixels: Int
        public let heightInVirtualPixels: Int
        // NOTE: refreshRateInHertz encodes as Double(0) if nil
        public let refreshRateInHertz: Double?
        // NOTE: isUsableForDesktopGui encodes as UInt8(1) if true and UInt8(0) if false
        public let isUsableForDesktopGui: Bool // NOTE: we can use this flag, in theory, to limit the resolutions we provide to user
        public let flags: UInt32

        private init(
            ioDisplayModeId: Int32,
            widthInPixels: Int,
            heightInPixels: Int,
            widthInVirtualPixels: Int,
            heightInVirtualPixels: Int,
            refreshRateInHertz: Double?,
            isUsableForDesktopGui: Bool,
            flags: UInt32
        ) {
            self.ioDisplayModeId = ioDisplayModeId
            self.widthInPixels = widthInPixels
            self.heightInPixels = heightInPixels
            self.widthInVirtualPixels = widthInVirtualPixels
            self.heightInVirtualPixels = heightInVirtualPixels
            self.refreshRateInHertz = refreshRateInHertz
            self.isUsableForDesktopGui = isUsableForDesktopGui
            self.flags = flags
        }
        
        // this function converts the data from a macOS CGDisplayMode class instance to a DisplayMode structure which we can use conveniently and which we can pass via exported cdecl functions
        public static func create(from cgDisplayMode: CGDisplayMode) -> DisplayMode? {
            // NOTE: if desired, we could use functions like CGDisplayModeCopyPixelEncoding here to retrieve bits-per-pixel etc.
            //       CGDisplayModeCopyPixelEncoding(...) <-- NOTE: we would also need a defer {...} block with an associated release call
            
            // convert the data we have gathered into our own struct
            let result = DisplayMode(
                ioDisplayModeId: cgDisplayMode.ioDisplayModeID,
                widthInPixels: cgDisplayMode.pixelWidth,
                heightInPixels: cgDisplayMode.pixelHeight,
                widthInVirtualPixels: cgDisplayMode.width,
                heightInVirtualPixels: cgDisplayMode.height,
                refreshRateInHertz: cgDisplayMode.refreshRate != 0 ? cgDisplayMode.refreshRate : nil,
                isUsableForDesktopGui: cgDisplayMode.isUsableForDesktopGUI(),
                flags: cgDisplayMode.ioFlags)
            
            return result
        }
        
        public static func ==(lhs: MorphicDisplay.DisplayMode, rhs: MorphicDisplay.DisplayMode) -> Bool {
            // NOTE: for purposes of equality, we do not check 'isUsableForDesktopGui'
            
            if lhs.ioDisplayModeId != rhs.ioDisplayModeId ||
                lhs.widthInPixels != rhs.widthInPixels ||
                lhs.heightInPixels != rhs.heightInPixels ||
                lhs.widthInVirtualPixels != rhs.widthInVirtualPixels ||
                lhs.heightInVirtualPixels != rhs.heightInVirtualPixels ||
                lhs.refreshRateInHertz != rhs.refreshRateInHertz {
                //
                return false
            }
            
            // otherwise, the arguments are equal
            return true
        }
        
        // NOTE: we automatically bridge MorphicDisplay.DisplayMode and CGDisplayMode for comparison purposes
        public static func ==(displayMode: MorphicDisplay.DisplayMode, cgDisplayMode: CGDisplayMode) -> Bool {
            // NOTE: for purposes of equality, we do not check 'isUsableForDesktopGui'

            if displayMode.ioDisplayModeId != cgDisplayMode.ioDisplayModeID ||
                displayMode.widthInPixels != cgDisplayMode.pixelWidth ||
                displayMode.heightInPixels != cgDisplayMode.pixelHeight ||
                displayMode.widthInVirtualPixels != cgDisplayMode.width ||
                displayMode.heightInVirtualPixels != cgDisplayMode.height {
                //
                return false
            }
            
            if (displayMode.refreshRateInHertz == nil && cgDisplayMode.refreshRate != 0) ||
                (displayMode.refreshRateInHertz != nil && displayMode.refreshRateInHertz! != cgDisplayMode.refreshRate) {
                //
                return false
            }
            
            // otherwise, the arguments are equal
            return true
        }
        
        public var isDefault: Bool{
            return flags & UInt32(kDisplayModeDefaultFlag) == UInt32(kDisplayModeDefaultFlag)
        }
        
        public var alwaysShow: Bool{
            return flags & UInt32(kDisplayModeAlwaysShowFlag) == UInt32(kDisplayModeAlwaysShowFlag)
        }
        
        public var neverShow: Bool{
            return flags & UInt32(kDisplayModeNeverShowFlag) == UInt32(kDisplayModeNeverShowFlag)
        }
        
        public var isStretched: Bool{
            return flags & UInt32(kDisplayModeStretchedFlag) == UInt32(kDisplayModeStretchedFlag)
        }
    }

    // MARK: - Display ID <-> UUID conversion functions
    
    public static func getDisplayUuidForDisplayId(_ displayId: UInt32) -> UUID? {
        // get the UUID for a display (and, as this is a CF 'Create' function, we are responsible for releasing the result...so we need to retain the value)
        guard let displayUuidAsCFUUID = CGDisplayCreateUUIDFromDisplayID(displayId)?.takeRetainedValue() else {
            // if we could not create the UUID from the display id, the display id was presumably not found
            return nil
        }
        
        // convert the CFUUID into a CFString (NOTE: whiel this is a CF 'Create' function, Swift will clean up and we don't need to retain the value manually)
        let displayUuidAsCFString = CFUUIDCreateString(kCFAllocatorDefault, displayUuidAsCFUUID)!
        
        // convert the CFUUID into a String so that we can then convert the string into a UUID; this is Apple's recommended method for bridging CFUUID and NSUUID/UUID
        let displayUuidAsNSString = displayUuidAsCFString as NSString
        let displayUuidAsString = displayUuidAsNSString as String
        
        let displayUUID = UUID(uuidString: displayUuidAsString)!
        return displayUUID
    }

    public static func getDisplayIdForDisplayUuid(_ displayUuid: UUID) -> UInt32? {
        // convert the UUID into a String so that we can then convert the string into a CFUUID; this is Apple's recommended method for bridging NSUUID/UUID and CFUUID
        let displayUuidAsNString = displayUuid.uuidString as NSString
        let displayUuidAsCFString = displayUuidAsNString as CFString
        
        // convert the CFString into a UUID (NOTE: while this is a CF 'Create' function, Swift will clean up and we don't need to retain the value manually)
        let displayUuidAsCfUUID = CFUUIDCreateFromString(kCFAllocatorDefault, displayUuidAsCFString)!
        
        // convert the display uuid (as cfuuid) into a display ID
        let displayId = CGDisplayGetDisplayIDFromUUID(displayUuidAsCfUUID)
        // NOTE: CGDisplayGetDisplayIDFromUUID returns 0 if the display UUID is not found; presumably, zero is an invalid display ID value
        if displayId == 0 {
            return nil
        }
        
        return displayId
    }
    
    // MARK: - Display from point functions
    
    public static func getDisplayUuidForPoint(_ point: NSPoint) -> UUID? {
        let allScreens = NSScreen.screens
        for screen in allScreens {
            // NOTE: although the NSMouseInRect function includes the word "Mouse", it should work for any point calculation
            if NSMouseInRect(point, screen.frame, false) == true {
                // we have found the screen which contains the point; get its display id
                guard let displayId = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                    // we could not get the displayId (which is represented as the screen number in NSScreen) for the
                    return nil
                }
                
                // convert the display id into a uuid
                guard let displayUuid = MorphicDisplay.getDisplayUuidForDisplayId(displayId) else {
                    assertionFailure("Converted NSScreen to displayId, but could not convert tbe displayId to its UUID equivalent")
                    return nil
                }
                
                return displayUuid
            }
        }
        
        // if we could not find the point on any screen, return nil
        return nil
    }

    // MARK: - Display enumeration functions
    
    public static func getActiveDisplayUuids() -> [UUID]? {
        var result: [UUID] = []

        // NOTE: here, we establish a "maximum number of displays" that we support for Core Graphics.  For our primary applications, this number is fairly irrelevant (since the first display we get information about should be the main display--which is usually what we'd be looking for).  But we may find other applications in the future where we want to reset the resolutions of multiple displays--in which case we can increment this constant.
        let maximumNumberOfDisplaysToSupport: UInt32 = 32 // NOTE: we use 32 active displays as a reasonable "upper bound" because we have to allocate an array to hold "up to max # supported" entries; otherwise we would just use UInt32.max
        //
        let activeDisplayIds = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(maximumNumberOfDisplaysToSupport))
        defer {
            activeDisplayIds.deallocate()
        }
        //
        var numberOfActiveDisplays: UInt32 = 0
        //
        if CGGetActiveDisplayList(maximumNumberOfDisplaysToSupport, activeDisplayIds, &numberOfActiveDisplays) != CGError.success {
            // if we could not get the list of active diplays, return nil
             return nil
        }
        
        // return active display IDs
        for index in 0..<Int(numberOfActiveDisplays) {
            let activeDisplayId = activeDisplayIds[index]
            guard let activeDisplayUuid = MorphicDisplay.getDisplayUuidForDisplayId(activeDisplayId) else {
                // NOTE: unless a display was disconnected during execution of this function or the OS switched between integrated and discrete graphics for a display, we should never encounter this error; return nil
                assertionFailure("Enumerated display ID, but could not convert it to its UUID equivalent")
                return nil
            }
            result.append(activeDisplayUuid)
        }
        
        return result
    }
    
    public static func getMainDisplayUuid() -> UUID? {
        // NOTE: this implementation fetches the first active display as the main display ID (as described in Apple's documentation); we may also want to consider using CGMainDisplayID() instead.
        
        // get the number of active displays
        guard let activeDisplayIds = MorphicDisplay.getActiveDisplayUuids() else {
            fatalError("could not retrieve list of active display ids.")
        }
        
        if activeDisplayIds.count < 1 {
            NSLog("No displays; this feature is not applicable on headless platforms.")
            return nil
        }
        
        let mainDisplayId = activeDisplayIds[0]

        return mainDisplayId
    }
    
    // MARK: Display mode functions
    
    // NOTE: this function returns nil if it encounters an error; we do this to distinguish an error condition ( nil ) from an empty set ( [] ).
    public static func getAllDisplayModes(for displayUuid: UUID) -> [MorphicDisplay.DisplayMode]? {
        var result: [MorphicDisplay.DisplayMode] = []
        
        // convert the display UUID to a display ID
        guard let displayId = MorphicDisplay.getDisplayIdForDisplayUuid(displayUuid) else {
            return nil
        }

        // get a list of modes for the specified display
        guard let allDisplayModesAsCGDisplayModeArray = MorphicDisplay.getAllDisplayModesAsCGDisplayModeArray(for: displayId) else {
            // if we cannot get a list of all display modes for this display, return nil
            return nil
        }

        for displayModeAsCGDisplayMode in allDisplayModesAsCGDisplayModeArray {
            guard let displayMode = DisplayMode.create(from: displayModeAsCGDisplayMode) else {
                // if we cannot process the mode-specific data, return nil
                return nil
            }
            
            result.append(displayMode)
        }
        
        return result
    }
    
    // NOTE: this fuction makes a copy of all the original OS-allocated CGDisplayMode values so that the result array is memory-safe to consume in Swift
    private static func getAllDisplayModesAsCGDisplayModeArray(for displayId: UInt32) -> [CGDisplayMode]? {
        var result: [CGDisplayMode] = []
        
        // get a list of modes for the specified display
        
        // NOTE: according to the CGDisplayCopyAllDisplayModes documentation, there are no options for CGDisplayCopyAllDisplayModes; however that documentation is incorrect as it supports (and we need to use) the kCGDisplayShowDuplicateLowResolutionModes option so that we get a list of all modes, both Retina and non-Retina.
        var dummyKeyCallBacks = kCFTypeDictionaryKeyCallBacks
        var dummyValueCallBacks = kCFTypeDictionaryValueCallBacks
        //
        let options: CFMutableDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &dummyKeyCallBacks, &dummyValueCallBacks)
        // NOTE: Swift manages Core Foundation memory for us; in other languages, be sure to CFRelease
//        defer {
//            CFRelease(options)
//        }
        //
        let displayShowDuplicateLowResolutionModesOption = kCGDisplayShowDuplicateLowResolutionModes
        CFDictionaryAddValue(options, unsafeBitCast(displayShowDuplicateLowResolutionModesOption, to: UnsafeRawPointer.self), unsafeBitCast(kCFBooleanTrue, to: UnsafeRawPointer.self))
        
        guard let displayModes = CGDisplayCopyAllDisplayModes(displayId, options) else {
            // if we could not get a list of display modes, return nil
            return nil
        }
        // NOTE: Swift automatically manages Core Foundation references, so this is included here just for porting purposes.
//        defer {
//            CFRelease(listOfModes)
//        }
        let numberOfDisplayModes = CFArrayGetCount(displayModes)
        
        for index in 0..<numberOfDisplayModes {
            guard let pointerToDisplayModeAsCGDisplayMode = CFArrayGetValueAtIndex(displayModes, CFIndex(index)) else {
                // if we cannot get the display mode details, return nil
                return nil
            }
            // make a copy of the CGDisplayMode to return to our caller
            let displayModeAsCGDisplayMode = unsafeBitCast(pointerToDisplayModeAsCGDisplayMode, to: CGDisplayMode.self)
            let pointerToCopyOfDisplayModeAsCGDisplayMode = UnsafeMutablePointer<CGDisplayMode>.allocate(capacity: 1)
            defer {
                pointerToCopyOfDisplayModeAsCGDisplayMode.deallocate()
            }
            pointerToCopyOfDisplayModeAsCGDisplayMode.initialize(to: displayModeAsCGDisplayMode)
            
            result.append(pointerToCopyOfDisplayModeAsCGDisplayMode.pointee)
        }
        
        return result
    }
    
    public static func getCurrentDisplayMode(for displayUuid: UUID) -> MorphicDisplay.DisplayMode? {
        // convert the display UUID to a display ID
        guard let displayId = MorphicDisplay.getDisplayIdForDisplayUuid(displayUuid) else {
            return nil
        }

        guard let displayModeAsCGDisplayMode = CGDisplayCopyDisplayMode(displayId) else {
            // if we could not get our current display's mode details, return nil
            return nil
        }
        // NOTE: Swift automatically manages Core Foundation references, so this is included here just for porting purposes.
        // NOTE: Swift also automatically maps the result to an object of type CGDisplayMode? so we don't even _have_ a pointer
//        defer {
//            CGDisplayModeRelease(pointerToDisplayModeAsCGDisplayMode)
//        }
        //
        guard let displayMode = DisplayMode.create(from: displayModeAsCGDisplayMode) else {
            // if we cannot process the mode-specific data, return nil
            return nil
        }

        return displayMode
    }

    public enum SetCurrentDisplayModeError: Error {
        case invalidDisplayMode
//        case unusableForDesktopGui
        case otherError
    }
    public static func setCurrentDisplayMode(for displayUuid: UUID, to newDisplayMode: MorphicDisplay.DisplayMode) throws {
//        // OPTIONAL: if we want, we can throw an error if the selected display mode is already known not to be suitable for a desktop GUI
//        if newDisplayMode.isUsableForDesktopGui == false {
//            throw SetCurrentDisplayModeError.unusableForDesktopGui
//        }
        
        // convert the display UUID to a display ID
        guard let displayId = MorphicDisplay.getDisplayIdForDisplayUuid(displayUuid) else {
            throw SetCurrentDisplayModeError.otherError
        }
        
        // obtain a CGDisplayMode object which matches the "newDisplayMode" struct passed in by our caller
        //
        // get a list of modes for the specified display
        guard let allDisplayModesAsCGDisplayModeArray = MorphicDisplay.getAllDisplayModesAsCGDisplayModeArray(for: displayId) else {
            // if we cannot get a list of all display modes for this display, throw an error
            throw SetCurrentDisplayModeError.otherError
        }
        //
        var newDisplayModeAsCGDisplayMode: CGDisplayMode? = nil
        for displayModeAsCGDisplayMode in allDisplayModesAsCGDisplayModeArray {
            // do an equality check (for now...based on the io display mode ID)
            if newDisplayMode == displayModeAsCGDisplayMode {
                newDisplayModeAsCGDisplayMode = displayModeAsCGDisplayMode
                break
            }
        }
        //
        if newDisplayModeAsCGDisplayMode == nil {
            // if we could not find the requested display mode in our available options, throw an error
            // NOTE: if we ever see this error thrown even though we chose a valid display mode option, change our equality check code (above) to match on the individual known-immutable properties like width and height instead (or have our function called with those specific "search" parameters)
            throw SetCurrentDisplayModeError.invalidDisplayMode
        }

        // now set up our display configuration transaction--and then execute it
        
        // ask Core Graphics to initialize a new configuration to use to change the display mode (using a pointer reference)
        // NOTE: the pointer is a pointer to a nullable object
        let pointerToConfig = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
        defer {
            pointerToConfig.deallocate()
        }
        //
        if CGBeginDisplayConfiguration(pointerToConfig) != CGError.success {
            // if we could not initialize a configuration object, throw na error
            throw SetCurrentDisplayModeError.otherError
        }
        // NOTE: Core Graphics requires that we "cancel" any config transaction which we don't complete
        var configRequiresCoreGraphicsCancel = false
        defer {
            if configRequiresCoreGraphicsCancel == true {
                // cancel (and release) the Core Graphics configuration
                CGCancelDisplayConfiguration(pointerToConfig.pointee)
            }
        }

        // configure the display with our configuration mode
        // NOTE: we pass "nil" to the options parameter; as of 30-Aug-2019 there are no options available for this API
        if CGConfigureDisplayWithDisplayMode(pointerToConfig.pointee, displayId, newDisplayModeAsCGDisplayMode, nil) != CGError.success {
            // if we could not configure the new display mode settings data, throw an error
            throw SetCurrentDisplayModeError.otherError
        }
        
        // specify our configuration option (i.e. "permanent display change, not just while our app is running or while we are logged into the current session")
        let configureOption: CGConfigureOption = CGConfigureOption.permanently

        // finally, complete the display mode change transaction using CGCompleteDisplayConfiguration
        if CGCompleteDisplayConfiguration(pointerToConfig.pointee, configureOption) == CGError.success {
            // NOTE: as we have called "complete", there is no need to cancel the transaction (so update this flag here so our DEFER block does not try to cleanup a completed config transaction)
            configRequiresCoreGraphicsCancel = false
            // NOTE:  the documentation is NOT clear as to if we need to "cancel" if CGCompleteDisplayConfiguration returns an error...but we do so out of an abundance of caution.  If this is in error, we should remove this "set to false" code to just before the CGCompleteDisplayConfiguration call
        } else {
            // if we could not set the display mode, throw an error
            throw SetCurrentDisplayModeError.otherError
        }
    }
}
