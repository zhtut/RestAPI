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
        .package(url: "https://gitee.com/ztgtut/SSNetwork.git", branch: "master"),
        .package(url: "https://gitee.com/ztgtut/SSCommon.git", branch: "master"),
        .package(url: "https://gitee.com/ztgtut/SSWebsocket.git", branch: "master"),
        .package(name: "Gzip", url: "https://github.com/1024jp/GzipSwift", from: "5.1.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RestAPI",
            dependencies: [
                "SSNetwork",
                "SSWebsocket",
                "Gzip",
                .product(name: "SSCommon", package: "SSCommon"),
                .product(name: "SSEncrypt", package: "SSCommon"),
                .product(name: "SSLog", package: "SSCommon"),
            ]),
    ]
)
