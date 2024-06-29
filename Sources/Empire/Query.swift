import LMDB
import PackedSerialize

public enum ComparisonOperator<Value: Comparable> {
	case equals(Value)
	case greaterThan(Value)
	case greaterOrEqual(Value)
	case lessThan(Value)
	case lessOrEqual(Value)
	case within([Value])

	var values: [Value] {
		switch self {
		case let .equals(v): [v]
		case let .greaterThan(v): [v]
		case let .greaterOrEqual(v): [v]
		case let .lessThan(v): [v]
		case let .lessOrEqual(v): [v]
		case let .within(v): v
		}
	}
}

extension ComparisonOperator: Equatable {
}

extension ComparisonOperator: Hashable where Value: Hashable {
}

public typealias QueryComponent = Comparable & Serializable

public struct Query<each Component: QueryComponent, Last: QueryComponent> {
	public let last: ComparisonOperator<Last>
	public let components: (repeat each Component)

	public init(_ value: repeat each Component, last: ComparisonOperator<Last>) {
		self.components = (repeat each value)
		self.last = last
	}
}
