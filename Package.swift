// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "EnumWindows",
  products: [
    .executable(name: "EnumWindows", targets: ["EnumWindows"]),
  ],
  dependencies: [
    .package(url: "https://github.com/CrazyFanFan/K3Pinyin", from: "2.0.0"),
  ],
  targets: [
    .target(
      name: "EnumWindows",
      dependencies: ["K3Pinyin"],
      path: "EnumWindows")
  ]
)