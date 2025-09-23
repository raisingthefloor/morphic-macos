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
import MorphicCore

/// Interface to the remote Morphic preferences server
public extension Service {
    
    // MARK: - Requests
    
    /// Fetch the preferences for the given user
    ///
    /// - parameters:
    ///   - user: The user's identifier
    ///   - completion: The block to call when the task has loaded
    ///   - user: The user, if the load was successful
    /// - returns: The URL session task that is making the remote request for user data
    func fetch(user identifier: String, completion: @escaping (_ user: User?) -> Void) -> Session.Task {
        let request = URLRequest(session: session, path: "v1/users/\(identifier)", method: .get)
        return session.runningTask(with: request, completion: completion)
    }
    
    /// Save the preferences for the given user
    ///
    /// - parameters:
    ///   - preferences: The user to save
    ///   - user: The user to save
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for user data
    func save(_ user: User, completion: @escaping (_ success: Bool) -> Void) -> Session.Task {
        let request = URLRequest(session: session, path: "v1/preferences/\(user.identifier)", method: .put, body: user)
        return session.runningTask(with: request, completion: completion)
    }
    
    // MARK: - Morphic User Communities
    
    func userCommunities(user: User, completion: @escaping (_ communities: UserCommunitiesResponse?) -> Void) -> Session.Task {
    	// NOTE: we do not urlescape the user identifiers (which we get from our server); if Swift doesn't do this natively we should consider doing it manually here out of an abundance of caution
        let request = URLRequest(session: session, path: "v1/users/\(user.identifier)/communities", method: .get)
        return session.runningTask(with: request, completion: completion)
    }

    func userCommunityDetails(user: User, community: UserCommunity, completion: @escaping (_ communityDetails: UserCommunityDetails?) -> Void) -> Session.Task {
    	// NOTE: we do not urlescape the user identifiers (which we get from our server); if Swift doesn't do this natively we should consider doing it manually here out of an abundance of caution
        let request = URLRequest(session: session, path: "v1/users/\(user.identifier)/communities/\(community.id)", method: .get)
        return session.runningTask(with: request, completion: completion)
    }
    
    struct UserCommunity: Codable {
        public var id: String
        public var name: String
        public var role: Role
        
        public enum Role: String, Codable {
            case manager = "manager"
            case member = "member"
        }
    }
    
    struct UserCommunitiesResponse: Codable {
        public var communities: [UserCommunity]
    }
    
    struct UserCommunityDetails: Codable {
        public var id: String
        public var name: String
        // NOTE: for legacy reasons, we need to still have the "bar" property for cached data (and we need to fall-back to it if bars is not populated)
        public var bar: Bar
        public var bars: [Bar]?
        
        public struct Bar: Codable {
            public var id: String
            public var name: String
            public var items: [BarItem]
            
            public func encodeAsMorphicBarItems() -> [[String: Interoperable?]] {
                var morphicbarItems: [[String: Interoperable?]] = []
                
                for item in self.items {
                    let itemConfiguration = item.configuration
                    var morphicBarItem: [String: Interoperable?] = [:]

                    switch item.kind {
                    case .action:
                        morphicBarItem["type"] = "action"
                        morphicBarItem["label"] = itemConfiguration.label
                        morphicBarItem["color"] = itemConfiguration.color
                        morphicBarItem["imageUrl"] = itemConfiguration.image_url
                        morphicBarItem["identifier"] = itemConfiguration.identifier
                        //
                        morphicbarItems.append(morphicBarItem)
                    case .application:
                        morphicBarItem["type"] = "application"
                        morphicBarItem["label"] = itemConfiguration.label
                        morphicBarItem["color"] = itemConfiguration.color
                        morphicBarItem["imageUrl"] = itemConfiguration.image_url
                        morphicBarItem["default"] = itemConfiguration.default
                        morphicBarItem["exe"] = itemConfiguration.exe
                        //
                        morphicbarItems.append(morphicBarItem)
                    case .link:
                        morphicBarItem["type"] = "link"
                        morphicBarItem["label"] = itemConfiguration.label
                        morphicBarItem["color"] = itemConfiguration.color
                        morphicBarItem["imageUrl"] = itemConfiguration.image_url
                        morphicBarItem["url"] = itemConfiguration.url
                        //
                        morphicbarItems.append(morphicBarItem)
                    }
                }
                
                return morphicbarItems
            }
        }
        
        // NOTE: we intentionally do not convert snake casing to lower camel case here; we may want to reconsider that in the future
        public struct BarItem: Codable {
            public var kind: BarItemKind
            public var is_primary: Bool
            // NOTE: in the future, we may want to dynamically parse the 'configuration' data as the respective subtype (rather than capturing it as a union with loose optionals and then validating the data higher up our call chain).
            public var configuration: BarConfigurationUnion
        }

        public enum BarItemKind: String, Codable {
            case link = "link"
            case application = "application"
            case action = "action"
        }
        
        // NOTE: this struct is the union of all possible ButtonConfiguration types and their subtypes (necessary for our current abstracted (codable) data decoding strategy)
        // NOTE: we intentionally do not convert snake casing to lower camel case here; we may want to reconsider that in the future
        public struct BarConfigurationUnion: Codable {
            public var color: String?
            public var `default`: String?
            public var exe: String?
            public var identifier: String?
            public var image_url: String?
            public var label: String?
            public var subkind: String?
            public var url: String?
        }
    }
}
