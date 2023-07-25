//
//  HTTPCookie.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Foundation

// MARK: - HTTPCookie

/// Convenience initializer for Foundation HTTPCookie
public extension HTTPCookie {

    // MARK: - Properties

    /// Stub URL adress
    private static let stubURLAddress = "http://localhost"

    /// Stub path
    private static let stubPath = "/"

    // MARK: - Initializers

    /// Convenience initializer
    /// - Parameters:
    ///   - name: key name
    ///   - value: key value
    convenience init(
        name: String,
        value: String
    ) {
        let cookieProperties = [
            HTTPCookiePropertyKey.name: name,
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.path: HTTPCookie.stubPath,
            HTTPCookiePropertyKey.originURL: HTTPCookie.stubURLAddress,
        ]
        self.init(properties: cookieProperties)!
    }
}
