extension String {
	/// sdbm hash of the string contents
	///
	/// As defined by http://www.cse.yorku.ca/~oz/hash.html.
	var sdbmHashValue: Int {
		var hash = 0
		
		for scalar in unicodeScalars {
			let c = Int(scalar.value)
			
			// opt into overflow with ampersand-prefixed operators
			hash = c &+ (hash << 6) &+ (hash << 16) &- hash
		}
		
		return hash
	}
}
