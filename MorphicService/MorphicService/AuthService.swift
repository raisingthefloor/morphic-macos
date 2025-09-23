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

/// Interface to the remote Morphic auth server
public extension Service {
    
    // MARK: - Requests
    
    /// Register using a username
    ///
    /// - parameters:
    ///   - user: The user info
    ///   - username: The usrename to login with
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func register(user: User, username: String, password: String, completion: @escaping (_ result: RegistrationResult) -> Void) -> Session.Task {
        let body = RegisterUsernameRequest(username: username, password: password, firstName: user.firstName, lastName: user.lastName, email: user.email)
        let request = URLRequest(session: session, path: "v1/register/username", method: .post, body: body)
        return session.runningTask(with: request) {
            (response: Response<AuthentiationResponse, RegisterUsernameBadRequest>) in
            switch response{
            case .success(let auth):
                completion(.success(authentication: auth))
            case .badRequest(let bad):
                guard let error = bad.error else{
                    completion(.error)
                    return
                }
                switch error{
                case .badPassword, .shortPassword:
                    completion(.badPassword)
                case .existingEmail, .existingUsername:
                    completion(.existingEmail)
                case .malformedEmail:
                    completion(.invalidEmail)
                }
            case .failed:
                completion(.error)
            }
        }
    }
    
    /// Register using a secret key
    ///
    /// - parameters:
    ///   - user: The user info
    ///   - key: The secret key to use
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func register(user: User, key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task {
        let body = RegisterKeyRequest(key: key, firstName: user.firstName, lastName: user.lastName)
        let request = URLRequest(session: session, path: "v1/register/key", method: .post, body: body)
        return session.runningTask(with: request, completion: completion)
    }
    
    func authenticate(credentials: Credentials, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task {
        if let keyCredentials = credentials as? KeyCredentials {
            return authenticate(key: keyCredentials.key, completion: completion)
        }
        if let usernameCredentials = credentials as? UsernameCredentials {
            return authenticate(username: usernameCredentials.username, password: usernameCredentials.password, completion: completion)
        }
        return session.runningTask(with: nil, completion: completion)
    }
    
    /// Authenticate using a username
    ///
    /// - parameters:
    ///   - username: The usrename to login with
    ///   - password: The password to use
    ///   - completion: The block to call when the task has completed
    ///   - authentication: The authentication response
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(username: String, password: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task {
        let body = AuthUsernameRequest(username: username, password: password)
        let request = URLRequest(session: session, path: "v1/auth/username", method: .post, body: body)
        return session.runningTask(with: request, completion: completion)
    }
    
    /// Authenticate using a secret key
    ///
    /// - parameters:
    ///   - key: The secret key
    ///   - completion: The block to call when the task has loaded
    ///   - success: Whether the save request succeeded
    /// - returns: The URL session task that is making the remote request for preferences data
    func authenticate(key: String, completion: @escaping (_ authentication: AuthentiationResponse?) -> Void) -> Session.Task {
        let body = AuthKeyRequest(key: key)
        let request = URLRequest(session: session, path: "v1/auth/key", method: .post, body: body)
        return session.runningTask(with: request, completion: completion)
    }
    
}

struct RegisterUsernameRequest: Codable {
    public var username: String
    public var password: String
    public var firstName: String?
    public var lastName: String?
    public var email: String?
}

struct RegisterUsernameBadRequest: Codable {
    public var error: InputError?
    
    public enum InputError: String, Codable {
        case existingUsername = "existing_username"
        case existingEmail = "existing_email"
        case malformedEmail = "malformed_email"
        case badPassword = "bad_password"
        case shortPassword = "short_password"
    }
}

struct RegisterKeyRequest: Codable {
    public var key: String
    public var firstName: String?
    public var lastName: String?
}

public enum RegistrationResult {
    case success(authentication: AuthentiationResponse)
    case badPassword
    case existingEmail
    case invalidEmail
    case error
}

struct AuthUsernameRequest: Codable {
    public var username: String
    public var password: String
}

struct AuthKeyRequest: Codable {
    public var key: String
}

public struct AuthentiationResponse: Codable {
    
    /// The authentication token to be used in the `X-Morphic-Auth-Token` header of subsequent requests
    public var token: String
    
    /// The authenticated user information
    public var user: User
}
