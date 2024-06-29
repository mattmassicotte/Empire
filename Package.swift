// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "Empire",
	products: [
		.library(name: "Empire", targets: ["Empire"]),
		.library(name: "LMDB", targets: ["LMDB"]),
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
		.target(
			name: "Empire",
			dependencies: ["LMDB"]
		),
		.testTarget(
			name: "EmpireTests",
			dependencies: ["Empire"]
		),
	],
	swiftLanguageVersions: [.v6]
)
