// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibrary",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "MediaLibraryApplication", targets: ["MediaLibraryApplication"]),
        .library(name: "MediaLibraryDomain", targets: ["MediaLibraryDomain"]),
        .library(name: "MediaLibraryInfrastructure", targets: ["MediaLibraryInfrastructure"]),
        .library(
            name: "MediaLibraryPresentation",
            targets: ["MediaLibraryPresentation", "MediaLibraryInfrastructure", "MediaLibraryApplication", "MediaLibraryDomain", "MediaLibraryDependencyInjection"]),
        .library(name: "MediaLibraryDependencyInjection", targets: ["MediaLibraryDependencyInjection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format", from: "509.0.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.0")
    ],
    targets: [
        // Application Layer
        .target(
            name: "MediaLibraryApplication",
            dependencies: [
                "MediaLibraryDomain"
            ],
            path: "Sources/Application"
        ),

        // Domain Layer
        .target(
            name: "MediaLibraryDomain",
            path: "Sources/Domain"
        ),

        // Infrastructure Layer
        .target(
            name: "MediaLibraryInfrastructure",
            dependencies: [
                "MediaLibraryDomain"
            ],
            path: "Sources/Infrastructure"
        ),

        // Presentation Layer
        .target(
            name: "MediaLibraryPresentation",
            dependencies: [
                "MediaLibraryApplication",
                "MediaLibraryDomain",
                "MediaLibraryDependencyInjection",
            ],
            path: "Sources/Presentation",
            resources: [
                .process("Resources")
            ]
        ),

        // Tests
        .testTarget(
            name: "DomainTests",
            dependencies: ["MediaLibraryDomain"]
        ),
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "MediaLibraryApplication",
                "MediaLibraryDomain",
                "MediaLibraryInfrastructure",
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "MediaLibraryInfrastructure",
                "MediaLibraryDomain",
            ]
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: [
                "MediaLibraryPresentation",
                "MediaLibraryApplication",
                "MediaLibraryDomain",
                .product(name: "ViewInspector", package: "ViewInspector")
            ]
        ),

        // DependencyInjection Layer
        .target(
            name: "MediaLibraryDependencyInjection",
            dependencies: [
                "MediaLibraryDomain",
                "MediaLibraryApplication",
                "MediaLibraryInfrastructure",
            ],
            path: "Sources/DependencyInjection"
        ),
    ]
)
