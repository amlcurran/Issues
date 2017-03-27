import Foundation

typealias JSON = [String: Any]
typealias JSONArray = [JSON]

class IssuesRepository {
    
    let resultQueue: DispatchQueue
    
    init(resultQueue: DispatchQueue) {
        self.resultQueue = resultQueue
    }
    
    func issues(onResult completion: @escaping ((Issues) -> Void), onError errorHandler: @escaping ((Error) -> Void)) {
        let request = URLRequest(authToken: token, query: graph())
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] maybeData, maybeResponse, maybeError in
            guard let data = maybeData else {
                self?.resultQueue.async {
                    errorHandler(ParseError.badResponse(response: maybeResponse))
                }
                return
            }
            do {
                let json = try JSONSerialization.json(from: data)
                let nodes = try issuesNodeArray(from: json)
                let issues = try Issues(nodes)
                self?.resultQueue.async {
                    completion(issues)
                }
            } catch let error {
                self?.resultQueue.async {
                    errorHandler(error)
                }
            }
        })
        task.resume()
    }
    
    private func graph() -> GraphQL {
        return .root("query", {
            .child(Node("repository", ["owner": "amlcurran", "name": "Social"]), {
                .child(Node("issues", ["first": 10, "states": GraphQLArray(["OPEN"])]), {
                    .child(Node("nodes"), {
                        .values(["title", "id"])
                    })
                })
            })
        })
    }
    
}

private func issuesNodeArray(from json: JSON) throws -> JSONArray {
    if let data = json["data"] as? JSON,
        let repository = data["repository"] as? JSON,
        let issuesJson = repository["issues"] as? JSON,
        let nodes = issuesJson["nodes"] as? JSONArray {
        return nodes
    }
    throw ParseError.invalidJSON(json: json)
}

fileprivate extension URLRequest {
    
    init(authToken: String, query: GraphQL) {
        self.init(url: URL(string: "https://api.github.com/graphql")!)
        let json = ["query": query.flattened]
        setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        timeoutInterval = 10
        httpMethod = "POST"
        cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        httpBody = try? JSONSerialization.data(withJSONObject: json)
    }
    
}

struct Issues: JSONArrayResponse {
    let results: [Issue]
    
    init(_ jsonNode: JSONArray) throws {
        results = jsonNode.flatMap({ issueJSON in
            return try? Issue(issueJSON)
        })
    }
}

struct Issue: JSONResponse {
    let title: String
    
    init(_ jsonNode: JSON) throws {
        guard let title = jsonNode["title"] as? String else {
            throw ParseError.missingKey
        }
        self.title = title
    }
}
