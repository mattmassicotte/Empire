// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EmpireBenchmarks",
	platforms: [.macOS(.v14)],
    products: [
		.executable(name: "EmpireBenchmarks", targets: ["EmpireBenchmarks"]),
    ],
	dependencies: [
		.package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
		.package(path: "../../Empire"),
	],
    targets: [
		.executableTarget(
			  name: "EmpireBenchmarks",
			  dependencies: [
				  .product(name: "Benchmark", package: "package-benchmark"),
				  "Empire",
			  ],
			  path: "Benchmarks/EmpireBenchmarks",
			  plugins: [
				  .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
			  ]
		),
    ]
)
