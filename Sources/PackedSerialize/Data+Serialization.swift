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
	public static func unpack(with deserializer: inout Deserializer) throws(DeserializeError) -> sending Data {
		let size: Int = Int(try UInt.unpack(with: &deserializer))

		let data = deserializer.rawSpan.extracting(first: size).withUnsafeBytes { buffer in
			Data(buffer)
		}

		try deserializer.advance(by: size)

		return data
	}
}
#endif

