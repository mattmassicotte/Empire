import Benchmark
import Foundation

import Empire

@IndexKeyRecord("key")
struct SmallRecord : Sendable {
	let key: Int
	let value: String
}

let benchmarks : @Sendable () -> Void = {
	Benchmark("Insert records per transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)

		let store = try Store(url: storeURL)
		
		benchmark.startMeasurement()
		
		for i in 0..<1000 {
			let record = SmallRecord(key: i, value: "\(i)")
			
			try await store.withTransaction { ctx in
				try ctx.insert(record)
			}
		}
    }
	
	Benchmark("Insert records one transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)
		
		let store = try Store(url: storeURL)
		
		benchmark.startMeasurement()
		
		try await store.withTransaction { ctx in
			for i in 0..<1000 {
				let record = SmallRecord(key: i, value: "\(i)")
				
				try ctx.insert(record)
			}
		}
	}
}
