// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimeRanger",
    platforms: [
        .macOS(.v10_15),
    ],    
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TimeRanger",
            targets: ["Ranger"]),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.10.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Ranger",
            dependencies: [
              .product(name: "Parsing", package: "swift-parsing")
            ]),
        .testTarget(
            name: "RangerTests",
            dependencies: ["Ranger"]),
    ]
)
