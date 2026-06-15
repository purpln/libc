// swift-tools-version: 6.2

import PackageDescription

let package = Package(name: "LibC", products: [
    .library(name: "LibC", targets: ["LibC"]),
], targets: [
    .target(name: "LibC", dependencies: [
        "LibCExternal"
    ]),
    .target(name: "LibCExternal"),
])

for target in package.targets {
    guard target.type != .plugin else { continue }
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings? += [
        //swift 6
        .enableUpcomingFeature("StrictConcurrency"),
        
        //swift 7
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
    ]
}
