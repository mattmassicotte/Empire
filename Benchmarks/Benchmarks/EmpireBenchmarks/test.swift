import Benchmark
import Foundation

import Empire

@IndexKeyRecord("key")
struct SmallRecord {
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
			
			try store.withTransaction { ctx in
				try ctx.insert(record)
			}
		}
    }
	
	Benchmark("Insert records in transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)
		
		let store = try Store(url: storeURL)
		
		benchmark.startMeasurement()

		try store.withTransaction { ctx in
			for i in 0..<1000 {
				let record = SmallRecord(key: i, value: "\(i)")
				
				try ctx.insert(record)
			}
		}
	}

	Benchmark("Insert records in nested transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)

		let store = try Store(url: storeURL)

		benchmark.startMeasurement()

		try store.withTransaction { parentCtx in
			try store.withTransaction(parent: parentCtx) { ctx in
				for i in 0..<1000 {
					let record = SmallRecord(key: i, value: "\(i)")
					
					try ctx.insert(record)
				}
			}
		}
	}

	Benchmark("Select 1000/1000 records in transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)

		let store = try Store(url: storeURL)

		try store.withTransaction { ctx in
			for i in 0..<1000 {
				let record = SmallRecord(key: i, value: "\(i)")

				try ctx.insert(record)
			}
		}

		benchmark.startMeasurement()

		_ = try store.withTransaction { ctx in
			try SmallRecord.select(in: ctx, key: .greaterOrEqual(0))
		}
	}

	Benchmark("Select 1000/1_000_000 records in transaction") { benchmark in
		let storeURL = URL(fileURLWithPath: "/tmp/empire_benchmark_store", isDirectory: true)
		try? FileManager.default.removeItem(at: storeURL)
		try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: false)

		let store = try Store(url: storeURL)

		try store.withTransaction { ctx in
			for i in 0..<1_000_000 {
				let record = SmallRecord(key: i, value: "\(i)")

				try ctx.insert(record)
			}
		}

		benchmark.startMeasurement()

		_ = try store.withTransaction { ctx in
			try SmallRecord.select(in: ctx, key: .range(0..<1000))
		}
	}
}
