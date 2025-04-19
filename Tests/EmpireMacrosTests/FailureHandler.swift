import Testing
import SwiftSyntaxMacrosGenericTestSupport

extension SourceLocation {
	init(_ location: TestFailureLocation) {
		self.init(
			fileID: location.fileID,
			filePath: location.filePath,
			line: location.line,
			column: location.column
		)
	}
}

extension Issue {
	@discardableResult
	static func record(_ failureSpec: TestFailureSpec) -> Issue {
		Issue.record(
			"\(failureSpec.message)",
			sourceLocation: SourceLocation(failureSpec.location)
		)
	}
}
