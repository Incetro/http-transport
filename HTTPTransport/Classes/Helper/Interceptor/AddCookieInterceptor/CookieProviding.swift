//
//  CookieProviding.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Foundation

// MARK: - CookieProviding

/// The place from where to get cookies
public protocol CookieProviding {

    /// Getting stored cookies
    func getStoredCookies() -> [HTTPCookie]
}
