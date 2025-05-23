import Benchmark
import Foundation

#if canImport(CoreData)
import CoreData

@objc(SmallRecord)
public class SmallRecord: NSManagedObject, Identifiable {
	@NSManaged public var value: String?
}

func configureCoreDataStack() -> NSManagedObjectContext {
	let url = Bundle.module.url(forResource: "CoreDataThing", withExtension: "momd", subdirectory: "TestData")!
	let model = NSManagedObjectModel(contentsOf: url)!
	let container = NSPersistentContainer(name: "CoreDataThing", managedObjectModel: model)

	try? FileManager.default.removeItem(atPath: "/tmp/core-data-test")
	try? FileManager.default.removeItem(atPath: "/tmp/core-data-test-shm")
	try? FileManager.default.removeItem(atPath: "/tmp/core-data-test-wal")

	container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/tmp/core-data-test")

	container.loadPersistentStores(completionHandler: { _, error in
		if let error {
			fatalError("error: \(error)")
		}
	})

	return container.newBackgroundContext()
}

let benchmarks : @Sendable () -> Void = {
	Benchmark("CoreData Insert records per transaction") { benchmark in
		let context = configureCoreDataStack()

		let description = NSEntityDescription.entity(forEntityName: "SmallRecord", in: context)!

		for i in 0..<1000 {
			let record = SmallRecord(entity: description, insertInto: context)

			record.value = "\(i)"

			try context.save()
		}
	}

	Benchmark("CoreData Insert records in transaction") { benchmark in
		let context = configureCoreDataStack()

		let description = NSEntityDescription.entity(forEntityName: "SmallRecord", in: context)!

		for i in 0..<1000 {
			let record = SmallRecord(entity: description, insertInto: context)

			record.value = "\(i)"
		}

		try context.save()
	}
}
#endif
