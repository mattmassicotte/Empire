import zlib

extension String {
	var checksum: Int {
		withCString { ptr in
			Int(crc32(0, ptr, UInt32(utf8.count)))
		}
	}
}
