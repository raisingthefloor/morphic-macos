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
import OSLog

private let logger = OSLog(subsystem: "MorphicCore", category: "Storage")

/// Application storage for Morphic on the local machine
public class Storage {
    
    /// The singleton `Storage` instance
    public private(set) static var shared = Storage()
    
    private static var applicationSupportDirectoryName: String? = nil
    
    public static func setApplicationSupportDirectoryName(_ applicationSupportDirectoryName: String) {
        Storage.applicationSupportDirectoryName = applicationSupportDirectoryName
    }
    
    private init() {
        guard let applicationSupportDirectoryName = Storage.applicationSupportDirectoryName else {
            preconditionFailure("Storage.setApplicationSupportDirectoryName(:) must be called before using this class.")
        }
        
        fileManager = .default
        root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(applicationSupportDirectoryName, isDirectory: true).appendingPathComponent("Data", isDirectory: true)
        queue = DispatchQueue(label: "org.raisingthefloor.Morphic.Storage", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    }
    
    public init(root url: URL) {
        fileManager = .default
        root = url
        queue = DispatchQueue(label: "org.raisingthefloor.Morphic.Storage", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    }
    
    /// The file manager on which to make requests
    private var fileManager: FileManager
    
    /// The root of the Morphic storage area
    private var root: URL?
    
    /// The background queue on which to perform file operations
    private var queue: DispatchQueue
    
    // MARK: - Preferences
    
    private func url(for identifier: String, type: Record.Type) -> URL? {
        return root?.appendingPathComponent(type.typeName, isDirectory: true).appendingPathComponent(identifier).appendingPathExtension("json")
    }
    
    /// Save the object
    ///
    /// - parameters:
    ///   - encodable: The object to save
    ///   - completion: The block to call when the save request completes
    ///   - success: Whether the object was saved successfully to disk
    public func save<RecordType>(record: RecordType, completion: @escaping (_ success: Bool) -> Void) where RecordType: Encodable, RecordType: Record {
        queue.async {
            guard let url = self.url(for: record.identifier, type: RecordType.self) else {
                os_log(.error, log: logger, "Could not obtain a valid file url for saving")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let encoder = JSONEncoder()
            guard let json = try? encoder.encode(record) else {
                os_log(.error, log: logger, "Failed to encode to JSON")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            do {
                try self.fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                os_log(.error, log: logger, "Failed to create directory")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            let success = self.fileManager.createFile(atPath: url.path, contents: json, attributes: nil)
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    public enum LoadStatus {
        case success
        case fileUrlMissing
        case couldNotReadFile
        case couldNotDecodeJson
    }
    
    /// Load the object for the given identifier
    ///
    /// - parameters:
    ///   - identifier: The identifier of the object to load
    ///   - completion: The block to call with the loaded object
    ///   - document: The loaded object, or `nil` if no such identifier was saved
    public func load<RecordType>(identifier: String, completion: @escaping (_ status: LoadStatus, _ document: RecordType?) -> Void) where RecordType: Decodable, RecordType: Record {
        queue.async {
            guard let url = self.url(for: identifier, type: RecordType.self) else {
                os_log(.error, log: logger, "Could not obtain a valid file url for loading")
                DispatchQueue.main.async {
                    completion(.fileUrlMissing, nil)
                }
                return
            }
            guard let data = self.fileManager.contents(atPath: url.path) else {
                os_log(.error, log: logger, "Could not read data")
                DispatchQueue.main.async {
                    completion(.couldNotReadFile, nil)
                }
                return
            }
            let decoder = JSONDecoder()
            guard let record = try? decoder.decode(RecordType.self, from: data) else {
                os_log(.error, log: logger, "Could not decode JSON")
                DispatchQueue.main.async {
                    completion(.couldNotDecodeJson, nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success, record)
            }
        }
    }
    
    /// Check if a record exists
    /// - parameters:
    ///   - identifier: The identifier of the object to load
    ///   - type: The type of record
    public func contains(identifier: String, type: Record.Type) -> Bool {
        guard let url = self.url(for: identifier, type: type) else {
            os_log(.error, log: logger, "Could not obtain a valid file url for loading")
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }
    
}
