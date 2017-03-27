import Foundation

typealias JSON = [String: Any]
typealias JSONArray = [JSON]

class IssuesRepository {

    func issues(_ completion: @escaping ((Issues) -> Void)) {
        let repository = GraphQL.constrainedNode("repository",
                ["owner": "amlcurran", "name": "Social"],
                .constrainedNode("issues",
                        ["first": 10, "states": GraphQLArray(values: ["OPEN"])],
                        .node("nodes",
                                .values("title"))))
        let graph = "query \(repository.flattened)"
        print(graph)
        let json = ["query" : graph]
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { maybeData, maybeResponse, maybeError in
            guard let data = maybeData,
                  let jsonAny = try? JSONSerialization.jsonObject(with: data),
                  let json = jsonAny as? [String: Any] else {
                print("Something went wrong \(maybeResponse)")
                return
            }
            if let data = json["data"] as? JSON,
               let repository = data["repository"] as? JSON,
               let issuesJson = repository["issues"] as? JSON,
               let nodes = issuesJson["nodes"] as? JSONArray {
                do {
                    let issues = try Issues(nodes)
                    completion(issues)
                } catch let error {
                    print("Parsing: \(error)")
                }
            } else {
                print("Something went wrong \(maybeResponse)")
                print("Something went wrong \(json)")
            }
        })
        task.resume()
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

protocol JSONArrayResponse {
    init(_ jsonNode: JSONArray) throws
}

protocol JSONResponse {
    init(_ jsonNode: JSON) throws
}

enum ParseError: Error {
    case missingKey
}