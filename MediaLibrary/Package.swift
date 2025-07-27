// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibrary",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MediaLibraryApplication", targets: ["Application"]),
        .library(name: "MediaLibraryDomain", targets: ["Domain"]),
        .library(name: "MediaLibraryInfrastructure", targets: ["Infrastructure"]),
        .library(
            name: "MediaLibraryPresentation",
            targets: ["Presentation", "Infrastructure", "Application", "Domain", "DependencyInjection"]),
        .library(name: "MediaLibraryDependencyInjection", targets: ["DependencyInjection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format", from: "509.0.0")
    ],
    targets: [
        // Application Layer
        .target(
            name: "Application",
            dependencies: [
                "Domain"
            ]
        ),

        // Domain Layer
        .target(
            name: "Domain"
        ),

        // Infrastructure Layer
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain"
            ]
        ),

        // Presentation Layer
        .target(
            name: "Presentation",
            dependencies: [
                "Application",
                "Domain",
                "DependencyInjection",
            ],
            resources: [
                .process("Resources")
            ]
        ),

        // Tests
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]
        ),
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "Application",
                "Domain",
                "Infrastructure",
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                "Domain",
            ]
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: [
                "Presentation",
                "Application",
                "Domain",
            ]
        ),

        // DependencyInjection Layer
        .target(
            name: "DependencyInjection",
            dependencies: [
                "Domain",
                "Application",
                "Infrastructure",
            ]
        ),
    ]
)
