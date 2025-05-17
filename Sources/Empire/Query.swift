import LMDB
import PackedSerialize

public protocol IndexKeyComparable: Comparable {
}

extension String: IndexKeyComparable {
}

extension UInt: IndexKeyComparable {
}

extension UInt32: IndexKeyComparable {
}

extension Int: IndexKeyComparable {
}

extension Int64: IndexKeyComparable {
}

#if canImport(Foundation)
import Foundation
extension UUID: IndexKeyComparable {
}

extension Date: IndexKeyComparable {
}
#endif

public enum ComparisonOperator<Value: IndexKeyComparable> {
	case greaterThan(Value)
	case greaterOrEqual(Value)
	case lessThan(Value)
	case lessOrEqual(Value)
	case within([Value])
	case range(Range<Value>)
	case closedRange(ClosedRange<Value>)
	
	public static func equals(_ value: Value) -> Self {
		Self.closedRange(value...value)
	}
}

extension ComparisonOperator: Equatable {
}

extension ComparisonOperator: Hashable where Value: Hashable {
}

public typealias QueryComponent = IndexKeyComparable & Serializable & Deserializable

public struct Query<each Component: QueryComponent, Last: QueryComponent> {
	public let last: ComparisonOperator<Last>
	public let components: (repeat each Component)
	public let limit: Int?

	public init(_ value: repeat each Component, last: ComparisonOperator<Last>, limit: Int? = nil) {
		self.components = (repeat each value)
		self.last = last
		self.limit = limit
	}
}

public enum QueryError: Error {
	case limitInvalid(Int)
	case unsupportedQuery
}
