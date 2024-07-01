import LMDB
import PackedSerialize

public protocol IndexKeyComparable: Comparable {
}

extension String: IndexKeyComparable {
}

extension UInt: IndexKeyComparable {
}

#if canImport(Foundation)
import Foundation
extension UUID: IndexKeyComparable {
}
#endif

public enum ComparisonOperator<Value: IndexKeyComparable> {
	case equals(Value)
	case greaterThan(Value)
	case greaterOrEqual(Value)
	case lessThan(Value)
	case lessOrEqual(Value)
	case within([Value])
	case range(Range<Value>)
	case closedRange(ClosedRange<Value>)
}

extension ComparisonOperator: Equatable {
}

extension ComparisonOperator: Hashable where Value: Hashable {
}

public typealias QueryComponent = IndexKeyComparable & Serializable

public struct Query<each Component: QueryComponent, Last: QueryComponent> {
	public let last: ComparisonOperator<Last>
	public let components: (repeat each Component)

	public init(_ value: repeat each Component, last: ComparisonOperator<Last>) {
		self.components = (repeat each value)
		self.last = last
	}
}

