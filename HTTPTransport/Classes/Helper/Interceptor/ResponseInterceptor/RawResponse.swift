//
//  RawResponse.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - RawResponse

/// Model for raw HTTP response with or without incoming error and data
public struct RawResponse {

    // MARK: - Properties

    /// URL request
    public let request: URLRequest?

    /// http URL response
    public let response: HTTPURLResponse?

    /// Response data
    public let data: Data?

    /// Response error
    public let error: Error?

    /// Default initializer
    /// - Parameters:
    ///   - request: URL request
    ///   - response: http URL response
    ///   - data: response data
    ///   - error: response error
    public init(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }
}
