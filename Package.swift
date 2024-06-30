// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "Empire",
	platforms: [
		.macOS(.v14),
		.iOS(.v17),
		.macCatalyst(.v17),
		.watchOS(.v10),
		.tvOS(.v17),
		.visionOS(.v1),
	],
	products: [
		.library(name: "Empire", targets: ["Empire"]),
		.library(name: "LMDB", targets: ["LMDB"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
	],
	targets: [
		.target(
			name: "CLMDB",
			path: "lmdb/libraries/liblmdb",
			sources: [
				"mdb.c",
				"midl.c"
			],
			publicHeadersPath: "."
		),
		.target(name: "LMDB", dependencies: ["CLMDB"]),
		.testTarget(name: "LMDBTests", dependencies: ["LMDB"]),
		.target(name: "PackedSerialize"),
		.testTarget(name: "PackedSerializeTests", dependencies: ["PackedSerialize"]),
		.macro(
			name: "EmpireMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
			]
		),
		.testTarget(
			name: "EmpireMacrosTests",
			dependencies: [
				"EmpireMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
			]
		),
		.target(
			name: "Empire",
			dependencies: ["LMDB", "EmpireMacros", "PackedSerialize"]
		),
		.testTarget(
			name: "EmpireTests",
			dependencies: ["Empire"]
		),
	],
	swiftLanguageVersions: [.v6]
)
