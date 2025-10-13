// swift-tools-version: 6.2

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
		.package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
	],
	targets: [
		.target(
			name: "CLMDB",
			path: "lmdb/libraries/liblmdb",
			sources: [
				"mdb.c",
				"midl.c"
			],
			publicHeadersPath: ".",
			cSettings: [
				.define("MDB_USE_POSIX_MUTEX", to: "1"),
				.define("MDB_USE_ROBUST", to: "0"),
			]
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
		.testTarget(name: "EmpireTests", dependencies: ["Empire"]),
		.target(name: "EmpireSwiftData", dependencies: ["Empire"]),
		.testTarget(name: "EmpireSwiftDataTests", dependencies: ["EmpireSwiftData"]),
	]
)
