import Foundation

typealias GraphFunction = () -> GraphQL

indirect enum GraphQL {

    case root(String, GraphQL)
    case node(String, GraphQL)
    case constrainedNode(String, [String: GraphQLPrimitive], GraphQL)
    case values(String)

    var flattened: String {
        switch self {
            case .root(let key, let graph):
                return "\(key) \(graph.flattened)"
            case .node(let key, let node):
                return "{ \(key) { \(node.flattened) } }"
            case .values(let value):
                return "\(value)"
            case .constrainedNode(let key, let options, let node):
                return "{ \(key)(\(toGraphQL(options))) \(node.flattened) }"
        }
    }

}

struct GraphQLArray: GraphQLPrimitive {
    let values: [String]

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