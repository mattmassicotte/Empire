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
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		var value: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
		let size = MemoryLayout<uuid_t>.size

		let data = UnsafeRawBufferPointer(start: buffer.baseAddress, count: size)

		withUnsafeMutableBytes(of: &value) { ptr in
			ptr.copyMemory(from: data)
		}

		buffer = UnsafeRawBufferPointer(rebasing: buffer[size...])

		self.init(uuid: value)
	}
}
#endif
