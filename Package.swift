// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StorageDone-iOS",
    platforms: [
        .macOS(.v10_14), .iOS(.v11), .tvOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "StorageDone",
            targets: ["StorageDone"]),
    ],
    dependencies: [
        .package(name: "CouchbaseLiteSwift",
            url: "https://github.com/couchbase/couchbase-lite-ios.git",
            from: "3.0.2"),
        .package(name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "StorageDone",
            dependencies: ["CouchbaseLiteSwift", "RxSwift"],
            path: "StorageDone",
            exclude: ["Info.plist"]
        )
    ]
)

