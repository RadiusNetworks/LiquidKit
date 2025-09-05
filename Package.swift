// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiquidKit",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LiquidKit",
            targets: ["LiquidKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Kitura/swift-html-entities.git", .exact("4.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LiquidKit",
            dependencies: [
                .product(name: "HTMLEntities", package: "swift-html-entities"),
            ]),
        .testTarget(
            name: "LiquidKitTests",
            dependencies: ["LiquidKit"]),
    ]
)
