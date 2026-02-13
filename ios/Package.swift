// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LoLCoach",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "LoLCoach", targets: ["LoLCoach"])
    ],
    targets: [
        .target(
            name: "LoLCoach",
            path: "LoLCoach"
        )
    ]
)
