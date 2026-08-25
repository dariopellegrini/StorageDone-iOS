// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StorageDone-iOS",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "StorageDone",
            targets: ["StorageDone"]),
    ],
    dependencies: [
        // Couchbase ha rimosso Package.swift dal repo a partire dal tag 3.4.0:
        // senza il tetto, SwiftPM prova i tag 4.x, non trova il manifest e la
        // risoluzione fallisce con "the package manifest at '/Package.swift'
        // cannot be accessed". 3.3.3 e' l'ultimo tag che ha ancora il manifest.
        .package(name: "CouchbaseLiteSwift",
            url: "https://github.com/couchbase/couchbase-lite-ios.git",
            Version(3, 2, 4)..<Version(3, 4, 0)),
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
