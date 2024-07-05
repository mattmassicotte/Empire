#if canImport(Foundation)
import Foundation

extension Date: Serializable {
	private var millisecondsSinceEpoch: Int {
		Int(self.timeIntervalSince1970 * 1000.0)
	}

	public var serializedSize: Int {
		millisecondsSinceEpoch.serializedSize
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		millisecondsSinceEpoch.serialize(into: &buffer)
	}
}

extension Date: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let millisecondsSinceEpoch = try Int(buffer: &buffer)

		self.init(timeIntervalSince1970: Double(millisecondsSinceEpoch) / 1000.0)
	}
}
#endif


