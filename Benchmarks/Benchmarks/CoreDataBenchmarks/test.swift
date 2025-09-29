import Benchmark
import Foundation

#if canImport(CoreData)
import CoreData

@objc(SmallRecord)
public class SmallRecord: NSManagedObject, Identifiable {
	@NSManaged public var key: Int
	@NSManaged public var value: String
}

func configureCoreDataStack() -> NSManagedObjectContext {
	let keyAttribute = NSAttributeDescription()
	keyAttribute.name = "key"
	keyAttribute.attributeType = .integer64AttributeType
	keyAttribute.isOptional = false

	let valueAttribute = NSAttributeDescription()
	valueAttribute.name = "value"
	valueAttribute.attributeType = .stringAttributeType
	valueAttribute.isOptional = false

	let smallModelEntity = NSEntityDescription()
	smallModelEntity.name = "SmallRecord"
	smallModelEntity.managedObjectClassName = NSStringFromClass(SmallRecord.self)
	smallModelEntity.properties = [keyAttribute, valueAttribute]

	let model = NSManagedObjectModel()

	model.entities = [smallModelEntity]

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

			record.key = i
			record.value = "\(i)"

			try context.save()
		}
	}

	Benchmark("CoreData Insert records in transaction") { benchmark in
		let context = configureCoreDataStack()

		let description = NSEntityDescription.entity(forEntityName: "SmallRecord", in: context)!

		for i in 0..<1000 {
			let record = SmallRecord(entity: description, insertInto: context)

			record.key = i
			record.value = "\(i)"
		}

		try context.save()
	}

	Benchmark("CoreData Select records") { benchmark in
		let context = configureCoreDataStack()

		let description = NSEntityDescription.entity(forEntityName: "SmallRecord", in: context)!

		for i in 0..<1000 {
			let record = SmallRecord(entity: description, insertInto: context)

			record.key = i
			record.value = "\(i)"
		}

		try context.save()

		benchmark.startMeasurement()

		let request = NSFetchRequest<SmallRecord>(entityName: "SmallRecord")
		request.predicate = NSPredicate(format: "key >= 0")
		request.sortDescriptors = [NSSortDescriptor(keyPath: \SmallRecord.key, ascending: true)]

		let _ = try context.fetch(request)
	}

}
#endif
