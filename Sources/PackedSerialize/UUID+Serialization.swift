#if canImport(Foundation)
import Foundation

extension UUID: Serializable {
	public var serializedSize: Int {
		MemoryLayout<uuid_t>.size
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		withUnsafeBytes(of: self.uuid) { ptr in
			buffer.copyMemory(from: ptr)
			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
		}
	}
}

extension UUID: Deserializable {
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending UUID {
		var value: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
		let size = MemoryLayout<uuid_t>.size

		value = try deserializer.unsafeLoad(of: uuid_t.self, sized: size)

		return UUID(uuid: value)
	}
}
#endif
