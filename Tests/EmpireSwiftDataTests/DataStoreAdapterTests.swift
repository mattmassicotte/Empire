#if canImport(SwiftData)
import Foundation
import SwiftData
import Testing

@testable import EmpireSwiftData

@Model
final class Item {
	var name: String
	
	init(name: String) {
		self.name = name
	}
}

@Suite(.serialized)
struct DataStoreAdapterTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/empire_test_store", isDirectory: true)

	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}

	@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
	@Test func createAdapter() async throws {
		let schema = Schema([Item.self])
		let config = DataStoreAdapter.Configuration(name: "name", schema: schema, url: Self.storeURL)
		
		let container = try ModelContainer(for: schema, configurations: [config])
		let context = ModelContext(container)
		
		let item = Item(name: "itemA")
		
		context.insert(item)
		
		try context.save()
	}
}

#endif
