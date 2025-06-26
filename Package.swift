// swift-tools-version: 5.5

import PackageDescription

let package = Package(name: "LibC", products: [
    .library(name: "LibC", targets: ["LibC"]),
], targets: [
    .target(name: "LibC", dependencies: [
        "LibCExternal"
    ], linkerSettings: [
        .linkedLibrary("android", .when(platforms: [.android])),
    ]),
    .target(name: "LibCExternal"),
])
