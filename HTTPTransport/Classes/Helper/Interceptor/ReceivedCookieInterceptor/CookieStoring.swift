//
//  CookieStoring.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Foundation

// MARK: - CookieStoring

/// The place where to store cookies
public protocol CookieStoring {

    /// Store Cookies
    /// - Parameter cookies: array of HTTPCookie
    func store(cookies: [HTTPCookie])
}
