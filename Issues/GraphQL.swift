import Foundation

typealias GraphFunction = () -> [GraphQL]

indirect enum GraphQL {

    case root(String, GraphFunction)
    case children(Node, GraphFunction)
    case values([String])

    var flattened: String {
        switch self {
            case .root(let key, let graph):
                return "\(key) { \(graph().flattened) }"
            case .children(let node, let graphs):
                return "\(node.flattened) { \(graphs().flattened) }"
            case .values(let values):
                return values.joined(separator: " ")
        }
    }

}

struct Node {
    let name: String
    let constraints: [String: GraphQLPrimitive]?
    let alias: String?

    init(_ name: String, alias: String? = nil, _ constraints: [String: GraphQLPrimitive]? = nil) {
        self.name = name
        self.alias = alias
        self.constraints = constraints
    }

    var flattened: String {
        if let alias = alias {
            return "\(alias): \(foo())"
        } else {
            return foo()
        }
    }
    
    private func foo() -> String {
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

extension Array where Iterator.Element == GraphQL {
    
    var flattened: String {
        return map({ graph in
            return graph.flattened
        }).joined(separator: "\n")
    }
    
}
