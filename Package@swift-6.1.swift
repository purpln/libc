// swift-tools-version: 6.1

import PackageDescription

let package = Package(name: "LibC", products: [
    .library(name: "LibC", targets: ["LibC"]),
], targets: [
    .target(name: "LibC", dependencies: [
        "LibCExternal"
    ]),
    .target(name: "LibCExternal"),
])
