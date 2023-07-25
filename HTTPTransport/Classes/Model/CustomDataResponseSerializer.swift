//
//  CustomDataResponseSerializer.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - CustomDataResponseSerializer

public final class CustomDataResponseSerializer<Value>: DataResponseSerializerProtocol {

    // MARK: - Aliases
    
    public typealias SerializedObject = Value

    // MARK: - Properties

    /// Serialize response
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value

    // MARK: - Initialazers

    /// Default initializer
    /// - Parameter serializeResponse: serialize response
    public init(
        serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value
    ) {
        self.serializeResponse = serializeResponse
    }

    // MARK: - Useful

    /// Perform serialize
    /// - Parameters:
    ///   - request: URL request
    ///   - response: http URL response
    ///   - error: response error
    ///   - data: response data
    /// - Throws: Value instance
    /// - Returns: serialize response
    public func serialize(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) throws -> Value {
        try serializeResponse(request, response, data, error)
    }
}
