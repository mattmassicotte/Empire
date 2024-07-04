#if canImport(Foundation)
import Foundation

extension Data: Serializable {
	public var serializedSize: Int {
		let count = self.count

		return count.serializedSize + count
	}

	public func serialize(into buffer: inout UnsafeMutableRawBufferPointer) {
		UInt(count).serialize(into: &buffer)

		self.withUnsafeBytes { ptr in
			buffer.copyMemory(from: ptr)
			buffer = UnsafeMutableRawBufferPointer(rebasing: buffer[ptr.count...])
		}
	}
}

extension Data: Deserializable {
	public init(buffer: inout UnsafeRawBufferPointer) throws {
		let size = try UInt(buffer: &buffer)
		let dataPtr = UnsafeRawBufferPointer(start: buffer.baseAddress, count: Int(size))

		self.init(dataPtr)

		buffer = UnsafeRawBufferPointer(rebasing: buffer[count...])
	}
}
#endif

