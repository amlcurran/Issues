import Foundation

typealias GraphFunction = () -> GraphQL

indirect enum GraphQL {

    case root(String, GraphFunction)
    case child(Node, GraphFunction)
    case values(String)

    var flattened: String {
        switch self {
            case .root(let key, let graph):
                return "\(key) { \(graph().flattened) }"
            case .child(let node, let graph):
                return "\(node.flattened) { \(graph().flattened) }"
            case .values(let value):
                return "\(value)"
        }
    }

}

struct Node {
    let name: String
    let constraints: [String: GraphQLPrimitive]?

    init(_ name: String, _ constraints: [String: GraphQLPrimitive]? = nil) {
        self.name = name
        self.constraints = constraints
    }

    var flattened: String {
        if let constraints = self.constraints {
            return "\(name)(\(toGraphQL(constraints)))"
        } else {
            return name
        }
    }

}

struct GraphQLArray: GraphQLPrimitive {
    let values: [String]

    public init(_ values: [String]) {
        self.values = values
    }

    var asValue: String {
        return "\(values)".replacingOccurrences(of: "\"", with: "")
    }
}

protocol GraphQLPrimitive {
    var asValue: String { get }
}

extension String: GraphQLPrimitive {
    var asValue: String {
        return "\"\(self)\""
    }
}

extension Int: GraphQLPrimitive {
    var asValue: String {
        return "\(self)"
    }
}

private func toGraphQL(_ options: [String: GraphQLPrimitive]) -> String {
    return options.map({ (entry: (String, GraphQLPrimitive)) in
        return "\(entry.0): \(entry.1.asValue)"
    }).joined(separator: ", ")
}