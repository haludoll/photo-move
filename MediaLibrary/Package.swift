// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibrary",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15) // Required by swift-dependencies, but only iOS is actually used
    ],
    products: [
        .library(name: "MediaLibraryApplication", targets: ["Application"]),
        .library(name: "MediaLibraryDomain", targets: ["Domain"]),
        .library(name: "MediaLibraryInfrastructure", targets: ["Infrastructure"]),
        .library(name: "MediaLibraryDependencyInjection", targets: ["DependencyInjection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format", from: "509.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ],
    targets: [
        // Application Layer
        .target(
            name: "Application",
            dependencies: [
                "Domain",
                "DependencyInjection",
                .product(name: "Dependencies", package: "swift-dependencies"),
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

        // DependencyInjection Layer
        .target(
            name: "DependencyInjection",
            dependencies: [
                "Domain",
                "Infrastructure",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),

        // Tests
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]),
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "Application",
                "Domain",
                "DependencyInjection",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                "Domain",
            ]),
    ])
