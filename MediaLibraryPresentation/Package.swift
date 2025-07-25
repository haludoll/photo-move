// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaLibraryPresentation",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MediaLibraryPresentation",
            targets: ["MediaLibraryPresentation"]
        )
    ],
    dependencies: [
        .package(path: "../MediaLibrary"),
        .package(path: "../AppFoundation")
    ],
    targets: [
        .target(
            name: "MediaLibraryPresentation",
            dependencies: [
                .product(name: "MediaLibraryDomain", package: "MediaLibrary"),
                .product(name: "MediaLibraryApplication", package: "MediaLibrary"),
                .product(name: "AppFoundation", package: "AppFoundation")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "MediaLibraryPresentationTests",
            dependencies: ["MediaLibraryPresentation"],
            path: "Tests"
        )
    ]
)