// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppFoundation",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppFoundation",
            targets: ["AppFoundation"])
    ],
    dependencies: [
        .package(path: "../MediaLibrary")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppFoundation",
            dependencies: [
                .product(name: "MediaLibraryPresentation", package: "MediaLibrary")
            ]),
        .testTarget(
            name: "AppFoundationTests",
            dependencies: ["AppFoundation"]),
    ])
