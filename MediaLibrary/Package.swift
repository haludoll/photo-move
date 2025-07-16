// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibrary",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "Presentation", targets: ["Presentation"]),
        .library(name: "Application", targets: ["Application"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Infrastructure", targets: ["Infrastructure"])
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.0")
    ],
    targets: [
        // Presentation Layer
        .target(
            name: "Presentation",
            dependencies: [
                "Application",
                "Domain"
            ]),

        // Application Layer
        .target(
            name: "Application",
            dependencies: [
                "Domain"
            ]),

        // Domain Layer
        .target(
            name: "Domain"),

        // Infrastructure Layer
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain"
            ]),

        // Tests
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]),
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "Application",
                "Domain"
            ]),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                "Domain"
            ]),
        .testTarget(
            name: "PresentationTests",
            dependencies: [
                "Presentation",
                "Application",
                "Domain"
            ])
    ])
