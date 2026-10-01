// swift-tools-version: 6.2
import PackageDescription

// Matches the app targets' build settings: Swift 5 mode, main actor by default,
// approachable concurrency and member import visibility.
let upcomingFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "SPAGCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SPAGCore", targets: ["SPAGCore"]),
    ],
    targets: [
        .target(
            name: "SPAGCore",
            resources: [.copy("Resources/Content")],
            swiftSettings: upcomingFeatures + [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "SPAGCoreTests",
            dependencies: ["SPAGCore"],
            swiftSettings: upcomingFeatures
        ),
    ],
    swiftLanguageModes: [.v5]
)
