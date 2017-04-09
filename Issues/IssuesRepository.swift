import Foundation
import SwiftyJSON

class IssuesRepository {
    
    let resultQueue: DispatchQueue
    
    init(resultQueue: DispatchQueue) {
        self.resultQueue = resultQueue
    }
    
    func issues(onResult completion: @escaping (([Repository]) -> Void), onError errorHandler: @escaping ((Error) -> Void)) {
        let request = URLRequest(authToken: token, query: graph())
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] maybeData, maybeResponse, maybeError in
            guard let data = maybeData else {
                self?.resultQueue.async {
                    errorHandler(ParseError.badResponse(response: maybeResponse))
                }
                return
            }
            let json = JSON(data: data)
            let nodes = json["data"].dictionaryValue
            let repositories = nodes.flatMap({ key, value in
                return try? Repository(value)
            })
            self?.resultQueue.async {
                completion(repositories)
            }
        })
        task.resume()
    }
    
    private func graph() -> GraphQL {
        return .root("query", {
            [
                repositoryGraph(named: "Social"),
                repositoryGraph(named: "Issues")
            ]
        })
    }
    
}

private func repositoryGraph(named name: String) -> GraphQL {
    return .children(Node("repository", alias: name, ["owner": "amlcurran", "name": name]), {
        [.values(["name"]),
         .children(Node("issues", ["first": 10, "states": GraphQLArray(["OPEN"])]), {
            return [.children(Node("nodes"), {
                [.values(["title", "id"])]
            })]
         })]
    })
        
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
        guard let title = jsonNode["title"].string else {
            throw ParseError.invalidJSON(json: jsonNode)
        }
        self.title = title
    }
}

struct Repository: JSONResponse {
    
    let name: String
    let issues: [Issue]
    
    init(_ jsonNode: JSON) throws {
        guard let name = jsonNode["name"].string,
            let issuesNode = jsonNode["issues"]["nodes"].array else {
                throw ParseError.invalidJSON(json: jsonNode)
        }
        self.name = name
        self.issues = issuesNode.flatMap({ issueJSON in
            return try? Issue(issueJSON)
        })
    }
    
}
