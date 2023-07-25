//
//  DataRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - DataRequest

/// Alamofire monkey patch
/// Allows intercepting HTTP responses & process response data.
extension DataRequest {

    /// HTTP response serializer
    /// - Parameter interceptors: array of interceptors
    /// - Returns: custom serializer
    static func httpResponseSerializer(
        interceptors: [HTTPResponseInterceptor] = []
    ) -> CustomDataResponseSerializer<HTTPResponse> {
        CustomDataResponseSerializer { (
            request,
            response,
            data,
            error
        ) throws -> HTTPResponse in
            let rawResponse = RawResponse(
                request: request,
                response: response,
                data: data,
                error: error
            )
            let refinedRawResponse = interceptors.reduce(rawResponse) { (
                currentRawResponse: RawResponse,
                interceptor: HTTPResponseInterceptor
            ) -> RawResponse in
                interceptor.intercept(response: currentRawResponse)
            }
            if let error = refinedRawResponse.error {
                throw error
            }
            guard let response: HTTPURLResponse = refinedRawResponse.response
            else {
                throw NSError.noHTTPResponse
            }
            let httpResponse: HTTPResponse = HTTPResponse(
                httpStatus:  HTTPStatusCode(httpURLResponse: response),
                headers: response.allHeaderFields as? [String: String] ?? [:],
                body: refinedRawResponse.data ?? Data(),
                request: refinedRawResponse.request
            )
            return httpResponse
        }
    }

    /// Response HTTP
    /// - Parameters:
    ///   - queue: current queue
    ///   - interceptors: array of interceptors
    ///   - completionHandler: completion handler
    /// - Returns: DataRequest instance
    @discardableResult func responseHTTP(
        queue: DispatchQueue = .main,
        interceptors: [HTTPResponseInterceptor] = [],
        completionHandler: @escaping (AFDataResponse<HTTPResponse>) -> Void
    ) -> Self {
        let responseSerializer = DataRequest.httpResponseSerializer(interceptors: interceptors)
        return response(
            queue: queue,
            responseSerializer: responseSerializer,
            completionHandler: completionHandler
        )
    }
}
