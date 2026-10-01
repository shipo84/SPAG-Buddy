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

/// Class login, answer upload, assignment download and remote content updates.
/// Only the School app links this package; the Home app must never depend on it.
let package = Package(
    name: "SPAGSchoolSync",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SPAGSchoolSync", targets: ["SPAGSchoolSync"]),
    ],
    dependencies: [
        .package(path: "../SPAGCore"),
    ],
    targets: [
        .target(
            name: "SPAGSchoolSync",
            dependencies: [.product(name: "SPAGCore", package: "SPAGCore")],
            swiftSettings: upcomingFeatures + [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "SPAGSchoolSyncTests",
            dependencies: [
                "SPAGSchoolSync",
                .product(name: "SPAGCore", package: "SPAGCore"),
            ],
            swiftSettings: upcomingFeatures
        ),
    ],
    swiftLanguageModes: [.v5]
)
