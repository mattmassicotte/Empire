#if canImport(Foundation)
import Foundation

extension Date: Serializable {
	private var millisecondsSinceEpoch: Int64 {
		Int64(self.timeIntervalSince1970 * 1000.0)
	}

	public var serializedSize: Int {
		millisecondsSinceEpoch.serializedSize
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		millisecondsSinceEpoch.serialize(into: &buffer)
	}
}

extension Date: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Date {
		let millisecondsSinceEpoch = try Int64.unpack(with: &deserializer)

		return Date(timeIntervalSince1970: Double(millisecondsSinceEpoch) / 1000.0)
	}
}
#endif


