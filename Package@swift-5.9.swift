// swift-tools-version: 5.9

import PackageDescription

let package = Package(name: "LibC", products: [
    .library(name: "LibC", targets: ["LibC"]),
], targets: [
    .target(name: "LibC", dependencies: [
        "LibCExternal"
    ]),
    .target(name: "LibCExternal"),
])
