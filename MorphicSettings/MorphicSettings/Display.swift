// Copyright 2020 Raising the Floor - International
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

import Foundation
import MorphicCore

public class Display {
    
    init(id: UInt32) {
        self.id = id
        possibleModes = findPossibleModes() ?? []
        normalMode = possibleModes.first(where: { $0.isDefault })
    }
    
    private var id: UInt32
    
    public static var main: Display? = {
        if let id = MorphicDisplay.getMainDisplayId(){
            return Display(id: id)
        }
        return nil
    }()
    
    public func zoom(to percentage: Double) -> Bool {
        guard let mode = self.mode(for: percentage) else{
            return false
        }
        do {
            try MorphicDisplay.setCurrentDisplayMode(for: id, to: mode)
            return true
        } catch {
            return false
        }
    }
    
    public func percentage(zoomingIn steps: Int) -> Double {
        guard let currentMode = currentMode, let normalMode = normalMode else {
            return 1
        }
        let target = possibleModes.reversed().first(where: { $0.widthInVirtualPixels < currentMode.widthInVirtualPixels }) ?? currentMode
        return Double(normalMode.widthInVirtualPixels) / Double(target.widthInVirtualPixels)
    }
    
    public func percentage(zoomingOut steps: Int) -> Double {
        guard let currentMode = currentMode, let normalMode = normalMode else {
            return 1
        }
        let target = possibleModes.first(where: { $0.widthInVirtualPixels > currentMode.widthInVirtualPixels }) ?? currentMode
        return Double(normalMode.widthInVirtualPixels) / Double(target.widthInVirtualPixels)
    }
    
    public var currentPercentage: Double {
        guard let currentMode = currentMode, let normalMode = normalMode else {
            return 1
        }
        return Double(normalMode.widthInVirtualPixels) / Double(currentMode.widthInVirtualPixels)
    }
    
    public var numberOfSteps: Int {
        return possibleModes.count
    }
    
    public var currentStep: Int {
        guard let current = currentMode else {
            return -1
        }
        return possibleModes.firstIndex(of: current) ?? -1
    }
    
    private var possibleModes: [MorphicDisplay.DisplayMode]!
    
    private var normalMode: MorphicDisplay.DisplayMode?
    
    private var currentMode: MorphicDisplay.DisplayMode? {
        return MorphicDisplay.getCurrentDisplayMode(for: id)
    }
    
    private func findPossibleModes() -> [MorphicDisplay.DisplayMode]? {
        guard let allDisplayModes = MorphicDisplay.getAllDisplayModes(for: id) else {
            return []
        }
        if allDisplayModes.count == 0 {
            return nil
        }
        guard let _ = currentMode else {
            return nil
        }
        
        // sort list of display modes (by width primarily, then height secondarily) in order of increasing size
        let sortedDisplayModes = sortDisplayModesByResolutionAscending(allDisplayModes)
        //
        // remove duplicate display mode entries
        let deduplicatedDisplayModes = filterOutDuplicateDisplayModes(sortedDisplayModes)
        //
        // remove all non-retina display mode options which have a corresponding retina display mode option
        let retinaPreferredDisplayModes = filterOutNonRetinaScaleAlternativeDisplayModes(deduplicatedDisplayModes)
        //
        // remove all retina "native" resolution options where a pixel-doubled retina option exists
        let pixelDoublePreferredDisplayModes = filterOutRetinaNativeScaleDisplayModes(retinaPreferredDisplayModes)
//        //
//        // suggested by Owen: filter out all display modes which do not use the current aspect ratio
//        let equalAspectDisplayModes = pixelDoublePreferredDisplayModes.filter({ $0.aspectRatio == currentMode.aspectRatio })
//        //
//        // suggested by Owen: filter out all display modes which do not use the same scale (i.e. Retina vs. non-Retina)
//        let equalScaleModes = equalAspectDisplayModes.filter({ $0.scale == currentMode.scale })
//        //
        // suggested by Owen: re-sort resolutions by custom "<" algorithm
        let sortedModes = pixelDoublePreferredDisplayModes.sorted(by: <)

        return sortedModes
    }
    
    private func mode(for percentage: Double) -> MorphicDisplay.DisplayMode? {
        guard let normalMode = normalMode else {
            return nil
        }
        let targetWidth = Int(round(Double(normalMode.widthInVirtualPixels) / percentage))
        let modes = possibleModes.map({ (abs($0.widthInVirtualPixels - targetWidth), $0) }).sorted(by: { $0.0 < $1.0 })
        return modes.first?.1
    }
    
    // MARK: display mode filter functions
    
    private func sortDisplayModesByResolutionAscending(_ displayModes: [MorphicDisplay.DisplayMode]) -> [MorphicDisplay.DisplayMode] {
        return displayModes.sorted(by: {
            // NOTE: the following sort indexes sort the data in a specific order (primary index first, secondary index second, etc.)
            
            // sort index: widthInVirtualPixels
            if $0.widthInVirtualPixels < $1.widthInVirtualPixels {
                return true
            } else if $0.widthInVirtualPixels > $1.widthInVirtualPixels {
                return false
            }
            
            // sort index: heightInVirtualPixels
            if $0.heightInVirtualPixels < $1.heightInVirtualPixels {
                return true
            } else if $0.heightInVirtualPixels > $1.heightInVirtualPixels {
                return false
            }
            
            // sort index: widthInPixels
            if $0.widthInPixels < $1.widthInPixels {
                return true
            } else if $0.widthInPixels > $1.widthInPixels {
                return false
            }
            
            // sort index: heightInPixels
            if $0.heightInPixels < $1.heightInPixels {
                return true
            } else if $0.heightInPixels > $1.heightInPixels {
                return false
            }

            // finally: if all indexes matched, return false
            return false
        })
    }
    
    private func filterOutDuplicateDisplayModes(_ displayModes: [MorphicDisplay.DisplayMode]) -> [MorphicDisplay.DisplayMode] {
        // copy the whole displayModes array into a working set
        var workingSet: [MorphicDisplay.DisplayMode] = displayModes
        
        // NOTE: this filter routine would be much faster if we pre-sorted the array; for simplicity we do not do so here
        
        var iFirstElement = 0
        while iFirstElement < workingSet.count {
            var iSecondElement = iFirstElement + 1
            while iSecondElement < workingSet.count {
                if workingSet[iFirstElement] == workingSet[iSecondElement] {
                    workingSet.remove(at: iSecondElement)
                } else {
                    iSecondElement += 1
                }
            }
            
            iFirstElement += 1
        }
        
        // return the remaining (non-duplicate) working set entries
        return workingSet
    }

    private func filterOutNonRetinaScaleAlternativeDisplayModes(_ displayModes: [MorphicDisplay.DisplayMode]) -> [MorphicDisplay.DisplayMode] {
        // remove all non-retina display mode options which have a corresponding retina display mode option
        
        // copy the whole displayModes array into a working set
        var workingSet: [MorphicDisplay.DisplayMode] = displayModes

        var iFirstElement = 0
        while iFirstElement < workingSet.count {
            var firstElementWasRemoved = false
            
            var iSecondElement = iFirstElement + 1
            while iSecondElement < workingSet.count {
                var secondElementWasRemoved = false
                
                if workingSet[iFirstElement].widthInVirtualPixels == workingSet[iSecondElement].widthInVirtualPixels &&
                    workingSet[iFirstElement].heightInVirtualPixels == workingSet[iSecondElement].heightInVirtualPixels {
                    // the two entries are the same virtual resolution (i.e. what the user sees in the resolution options)
                    
                    // remove the option which is non-retina
                    if workingSet[iFirstElement].widthInPixels > workingSet[iSecondElement].widthInPixels &&
                        workingSet[iFirstElement].heightInPixels > workingSet[iSecondElement].heightInPixels {
                        // the first entry is the higher-resolution entry; remove the second element
                        workingSet.remove(at: iSecondElement)

                        // mark "secondElementWasRemoved" as true so it won't be incremented at the end of the current loop iteration
                        secondElementWasRemoved = true
                    } else {
                        // otherwise, remove the first element
                        workingSet.remove(at: iFirstElement)
                        
                        // mark "firstElementWasRemoved" as true so that it won't be incremented at the end fo the current (outer) loop iteration
                        firstElementWasRemoved = true
                        // break out the of the loop so that we start re-seeking at the next "first element" position
                        break
                    }
                }

                if secondElementWasRemoved == false {
                    // NOTE: we only increment iSecondElement if the second element was NOT removed; otherwise we need to continue processing at the same position
                    iSecondElement += 1
                }
            }
            
            if firstElementWasRemoved == false {
                // NOTE: we only increment iFirstElement if the first element was NOT removed; otherwise we need to continue processing at the same position
                iFirstElement += 1
            }
        }
        
        // return the remaining ("non-retina mode option removed where matching retina mode was present") working set entries
        return workingSet
    }

    private func filterOutRetinaNativeScaleDisplayModes(_ displayModes: [MorphicDisplay.DisplayMode]) -> [MorphicDisplay.DisplayMode] {
        // remove all retina display mode options that are "native resolution" (instead of using pixel doubling)
        
        // copy the whole displayModes array into a working set
        var workingSet: [MorphicDisplay.DisplayMode] = displayModes
        
        var iFirstElement = 0
        while iFirstElement < workingSet.count {
            var firstElementWasRemoved = false
            
            var iSecondElement = iFirstElement + 1
            while iSecondElement < workingSet.count {
                var secondElementWasRemoved = false
                
                if workingSet[iFirstElement].widthInPixels == workingSet[iSecondElement].widthInPixels &&
                    workingSet[iFirstElement].heightInPixels == workingSet[iSecondElement].heightInPixels {
                    // the two entries are the same physical resolution
                    
                    // remove the option which is retina's "native" resolution (because the dots would be TOO small)
                    if workingSet[iFirstElement].widthInVirtualPixels < workingSet[iSecondElement].widthInVirtualPixels &&
                        workingSet[iFirstElement].heightInVirtualPixels < workingSet[iSecondElement].heightInVirtualPixels {
                        // the first entry is the non-native (pixel doubled) entry; remove the second element
                        workingSet.remove(at: iSecondElement)
                        
                        // mark "secondElementWasRemoved" as true so it won't be incremented at the end of the current loop iteration
                        secondElementWasRemoved = true
                    } else {
                        // otherwise, remove the first element
                        workingSet.remove(at: iFirstElement)
                        
                        // mark "firstElementWasRemoved" as true so that it won't be incremented at the end fo the current (outer) loop iteration
                        firstElementWasRemoved = true
                        // break out the of the loop so that we start re-seeking at the next "first element" position
                        break
                    }
                }
                
                if secondElementWasRemoved == false {
                    // NOTE: we only increment iSecondElement if the second element was NOT removed; otherwise we need to continue processing at the same position
                    iSecondElement += 1
                }
            }
            
            if firstElementWasRemoved == false {
                // NOTE: we only increment iFirstElement if the first element was NOT removed; otherwise we need to continue processing at the same position
                iFirstElement += 1
            }
        }
        
        // return the remaining ("non-retina mode option removed where matching retina mode was present") working set entries
        return workingSet
    }
    
}

public class DisplayZoomHandler: ClientSettingHandler {
    
    public override func read(completion: @escaping (SettingHandler.Result) -> Void) {
        guard let percentage = Display.main?.currentPercentage else {
            completion(.failed)
            return
        }
        completion(.succeeded(value: percentage))
    }
    
    public override func apply(_ value: Interoperable?, completion: @escaping (_ success: Bool) -> Void) {
        if let intValue = value as? Int{
            apply(Double(intValue), completion: completion)
            return
        }
        guard let percentage = value as? Double else{
            completion(false)
            return
        }
        let success = Display.main?.zoom(to: percentage) ?? false
        completion(success)
    }
    
}

private extension MorphicDisplay.DisplayMode {
    
    var stringRepresentation: String {
        var str = "\(widthInVirtualPixels)x\(heightInVirtualPixels)"
        if widthInPixels != widthInVirtualPixels || heightInPixels != heightInPixels{
            str += " (\(widthInPixels)x\(heightInPixels))"
        }
        if let refresh = integerRefresh{
            str += " @\(refresh)Hz"
        }
        return str
    }
    
    static func <(_ a: MorphicDisplay.DisplayMode, _ b: MorphicDisplay.DisplayMode) -> Bool {
        var diff = a.widthInVirtualPixels - b.widthInVirtualPixels
        if diff == 0{
            diff = a.widthInPixels - b.widthInPixels
            if diff == 0{
                diff = Int(a.refreshRateInHertz ?? 0) - Int(b.refreshRateInHertz ?? 0)
                if diff == 0 {
                    diff = Int(a.ioDisplayModeId) - Int(b.ioDisplayModeId)
                }
            }
        }
        return diff < 0
    }
    
    var integerRefresh: Int? {
        guard let refresh = refreshRateInHertz else {
            return nil
        }
        return Int(refresh)
    }
    
    struct AspectRatio {
        public var width: Int
        public var height: Int
        
        init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
        
        public var value: Double {
            return Double(width) / Double(height)
        }
        
        static func ==(_ a: AspectRatio, _ b: AspectRatio) -> Bool {
            return abs(a.value - b.value) < 0.1
        }
    }
    
    var aspectRatio: AspectRatio {
        return AspectRatio(width: widthInVirtualPixels, height: heightInVirtualPixels)
    }
    
    var scale: Int {
        return widthInVirtualPixels / widthInPixels
    }
    
}

