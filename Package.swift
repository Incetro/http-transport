// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTPTransport",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "HTTPTransport",
            targets: ["HTTPTransport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.4.3"),
    ],
    targets: [
        .target(
            name: "HTTPTransport",
            dependencies: ["Alamofire"],
            path: "./HTTPTransport"
        ),
        .testTarget(
            name: "HTTPTransportTests",
            dependencies: ["HTTPTransport"],
            path: "./HTTPTransportTests"
        ),
    ]
)
