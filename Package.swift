// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "vim-with-a-hat",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.13.0"),
    ],
    targets: [
        .executableTarget(
            name: "vim-with-a-hat",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/vim-with-a-hat",
            resources: [
                .copy("Resources/app-icon.png"),
            ]
        ),
    ]
)
