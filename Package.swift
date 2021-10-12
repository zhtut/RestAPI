// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RestAPI",
    platforms: [ .iOS(.v13),
                 .macOS(.v10_15) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RestAPI",
            targets: ["RestAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://gitee.com/ztgtut/SSNetwork.git", from: "1.0.0"),
        .package(url: "https://gitee.com/ztgtut/SSCommon.git", from: "1.0.0"),
        .package(url: "https://gitee.com/ztgtut/SSWebsocket.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RestAPI",
            dependencies: [
                "SSNetwork",
                "SSWebsocket",
                .product(name: "SSCommon", package: "SSCommon"),
                .product(name: "SSEncrypt", package: "SSCommon"),
                .product(name: "SSLog", package: "SSCommon"),
            ]),
    ]
)
