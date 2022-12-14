// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RestAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RestAPI",
            targets: ["RestAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/zhtut/SSNetwork.git", branch: "main"),
//        .package(name: "SSNetwork", path: "../Tools/SSNetwork"),
        .package(url: "https://github.com/zhtut/SSWebsocket.git", branch: "main"),
//        .package(name: "SSWebsocket", path: "../Tools/SSWebsocket"),
        .package(url: "https://github.com/zhtut/SSCommon.git", branch: "main"),
//        .package(name: "SSCommon", path: "../Tools/SSCommon"),
        .package(url: "https://github.com/zhtut/SSLog.git", branch: "main"),
//        .package(name: "SSLog", path: "../Tools/SSLog"),
        .package(url: "https://github.com/zhtut/SSEncrypt.git", branch: "main"),
//        .package(name: "SSEncrypt", path: "../Tools/SSEncrypt"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RestAPI", 
            dependencies: [
                "SSNetwork",
                "SSWebsocket",
                "SSCommon",
                "SSEncrypt",
                "SSLog",
            ]),
        .testTarget(name: "RestAPITests", dependencies: ["RestAPI"]),
    ]
)
