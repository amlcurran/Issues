import Foundation

typealias JSON = [String: Any]
typealias JSONArray = [JSON]

class IssuesRepository {
    
    let resultQueue: DispatchQueue
    
    init(resultQueue: DispatchQueue) {
        self.resultQueue = resultQueue
    }
    
    func issues(onResult completion: @escaping ((Repository) -> Void), onError errorHandler: @escaping ((Error) -> Void)) {
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
                print(json)
                let nodes = try issuesNodeArray(from: json)
                let issues = try Repository(nodes)
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
            [
                repositoryGraph(named: "Social")
            ]
        })
    }
    
}

private func repositoryGraph(named name: String) -> GraphQL {
    return .children(Node("repository", ["owner": "amlcurran", "name": "Social"]), {
        [.values(["name"]),
         .children(Node("issues", ["first": 10, "states": GraphQLArray(["OPEN"])]), {
            return [.children(Node("nodes"), {
                [.values(["title", "id"])]
            })]
         })]
    })
}

private func issuesNodeArray(from json: JSON) throws -> JSON {
    if let data = json["data"] as? JSON,
        let repository = data["repository"] as? JSON {
        return repository
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

struct Issue: JSONResponse {
    let title: String
    
    init(_ jsonNode: JSON) throws {
        guard let title = jsonNode["title"] as? String else {
            throw ParseError.missingKey
        }
        self.title = title
    }
}

struct Repository: JSONResponse {
    
    let name: String
    let issues: [Issue]
    
    init(_ jsonNode: JSON) throws {
        guard let name = jsonNode["name"] as? String,
            let issuesNode = jsonNode["issues"] as? JSON,
            let issues = issuesNode["nodes"] as?  JSONArray else {
                throw ParseError.missingKey
        }
        self.name = name
        self.issues = try issues.flatMap({ issueJSON in
            return try Issue(issueJSON)
        })
    }
    
}
