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

import Foundation

public class AsyncUtils {
    // NOTE: this function returns true if the condition matched; it returns false upon timeout
    public static func wait(atMost: TimeInterval, for condition: @escaping () throws -> Bool) async throws -> Bool {
        guard atMost >= 0.0 else {
            fatalError("Argument 'atMost' cannot be a negative value")
        }

        // calculate the point in time at which we should stop waiting
        // NOTE: ProcessInfo.processInfo.systemUptime measures the system uptime (i.e. does not count when the device is asleep); we believe that this refers only to standby, but if the processor is "sleeping" while the user is working, then we need to rethink this logic and
        //       use kern.boottime instead; we prefer system update here both because it's straightforward and also because we want to wait for the specified amount of time even if computer went to sleep during our operation
        //       see: https://developer.apple.com/forums/thread/101874
        let waitUntilTimestamp = ProcessInfo.processInfo.systemUptime + atMost
        
        // NOTE: in the future, we may want to let the caller specify a wait interval; for now, we're using 20ms to provide a good balance of CPU cycle usage and responsiveness
        let waitInterval = 20.0
        while true {
            var conditionResult: Bool
            do {
                conditionResult = try condition()
            } catch let error {
                throw error
            }
            if conditionResult == true {
                return true
            }
            
            let currentWaitInterval = min(waitInterval, waitUntilTimestamp - ProcessInfo.processInfo.systemUptime)
            if currentWaitInterval <= 0 {
                // timeout; return false
                return false
            }
            
            // wait for the specified wait interval before we re-check the condition
            guard let _ = try? await Task.sleep(nanoseconds: UInt64((currentWaitInterval / 1_000) * Double(NSEC_PER_SEC))) else {
                // in case that Task.sleep threw an exception, abort and return false; this should only happen when the process is being torn down, etc. as we do not cancel the timer ourselves
                return false
            }
        }
    }

    // NOTE: this function returns true if the condition matched; it returns false upon timeout
    public static func wait(atMost: TimeInterval, for condition: @escaping () -> Bool) async -> Bool {
        guard atMost >= 0.0 else {
            fatalError("Argument 'atMost' cannot be a negative value")
        }

        // calculate the point in time at which we should stop waiting
        // NOTE: ProcessInfo.processInfo.systemUptime measures the system uptime (i.e. does not count when the device is asleep); we believe that this refers only to standby, but if the processor is "sleeping" while the user is working, then we need to rethink this logic and
        //       use kern.boottime instead; we prefer system update here both because it's straightforward and also because we want to wait for the specified amount of time even if computer went to sleep during our operation
        //       see: https://developer.apple.com/forums/thread/101874
        let waitUntilTimestamp = ProcessInfo.processInfo.systemUptime + atMost

        // NOTE: in the future, we may want to let the caller specify a wait interval; for now, we're using 20ms to provide a good balance of CPU cycle usage and responsiveness
        let waitInterval = 20.0
        while condition() == false {
            let currentWaitInterval = min(waitInterval, waitUntilTimestamp - ProcessInfo.processInfo.systemUptime)
            if currentWaitInterval <= 0 {
                // timeout; return false
                return false
            }

            // wait for the specified wait interval before we re-check the condition
            guard let _ = try? await Task.sleep(nanoseconds: UInt64((currentWaitInterval / 1_000) * Double(NSEC_PER_SEC))) else {
                // in case that Task.sleep threw an exception, abort and return false; this should only happen when the process is being torn down, etc. as we do not cancel the timer ourselves
                return false
            }
        }

        // if we reach here, the condition returned true
        return true
    }
    
    // NOTE: this legacy function does not take system sleep time into account (which may or may not be a problem)
    //       see: https://developer.apple.com/forums/thread/101874
    public static func wait(atMost: TimeInterval, for condition: @escaping () -> Bool, completion: @escaping (_ success: Bool) -> Void) {
        guard !condition() else {
            completion(true)
            return
        }
        var checkTimer: Timer?
        DispatchQueue.main.async {
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: atMost, repeats: false) {
                _ in
                checkTimer?.invalidate()
                completion(condition())
            }
            var checkInterval: TimeInterval = 0.1
            var check: (() -> Void)!
            check = {
                checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: false) {
                    _ in
                    if condition() {
                        timeoutTimer.invalidate()
                        completion(true)
                    } else {
                        checkInterval *= 2
                        check()
                    }
                }
            }
    
            check()
        }
    }
    
    public static func syncWait(atMost: TimeInterval, for condition: @escaping () -> Bool) {
        var conditionIsMet = false

        let conditionLock = NSCondition()
        conditionLock.lock()
        defer {
            conditionLock.unlock()
        }
        
        guard !condition() else {
            return
        }
        var checkTimer: Timer?
        var timeoutTimer: Timer? = nil
        DispatchQueue.global(qos: .background).async {
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: atMost, repeats: false) {
                _ in
                checkTimer?.invalidate()
                conditionIsMet = true
                conditionLock.signal()
            }
            RunLoop.current.run()
        }
        var checkInterval: TimeInterval = 0.1
        var check: (() -> Void)!
        check = {
            checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: false) {
                _ in
                if condition() {
                    timeoutTimer?.invalidate()
                    conditionIsMet = true
                    conditionLock.signal()
                } else {
                    checkInterval *= 2
                    check()
                }
            }
        }
        DispatchQueue.global(qos: .background).async {
            check()
            RunLoop.current.run()
        }

        while conditionIsMet == false {
            // NOTE: we use waitInterval for the extreme edge case that the condition was met in a timeslice between when we checked and when we started to wait
            let waitInterval: TimeInterval = 0.1
            conditionLock.wait(until: Date().addingTimeInterval(waitInterval))
        }
    }
}
