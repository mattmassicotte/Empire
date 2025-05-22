import Foundation
import Testing

import Empire

// define your records with types
@IndexKeyRecord("name")
struct Person {
	let name: String
	let age: Int
}

@Suite(.serialized)
struct ExampleTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_example_store", isDirectory: true)

	let store: Store

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)

		self.store = try Store(url: Self.storeURL)
	}

	@MainActor
	@Test func readmeHeroExample() async throws {
		// create a local database
		let store = try BackgroundableStore(url: Self.storeURL)

		// interact with it using transactions
		try store.main.withTransaction { context in
			try context.insert(Person(name: "Korben", age: 45))
			try context.insert(Person(name: "Leeloo", age: 2000))
		}

		// run queries
		let records = try store.main.withTransaction { context in
			try Person.select(in: context, limit: 1, name: .lessThan("Zorg"))
		}

		print(records.first!) // Person(name: "Leeloo", age: 2000)

		// move work to the background
		try await store.background.withTransaction { ctx in
			try Person.delete(in: ctx, name: "Korben")
		}
	}
}
