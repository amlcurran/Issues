import Foundation
import SwiftyJSON

class IssuesRepository {

    let resultQueue: DispatchQueue
    let session: URLSession

    init(resultQueue: DispatchQueue, session: URLSession = .shared) {
        self.resultQueue = resultQueue
        self.session = session
    }

    func issues(onResult completion: @escaping (([Repository]) -> Void), onError errorHandler: @escaping ((Error) -> Void)) {
        let request = URLRequest(authToken: token, query: graph())
        let task = session.dataTask(with: request,
            onSuccess: { [weak self] data, _ in
                let json = JSON(data: data)
                let repositories = json["data"].dictionaryValue.flatMap(asRepositories)
                self?.resultQueue.async {
                    completion(repositories)
                }
            },
            onError: { error, _ in
                errorHandler(error)
            })
        task.resume()
    }

    private func graph() -> GraphQL {
        return .root("query", {
            [
                repositoryGraph(named: "Social", owner: "amlcurran"),
                repositoryGraph(named: "Issues", owner: "amlcurran"),
                repositoryGraph(named: "website", owner: "amlcurran")
            ]
        })
    }

}

private func asRepositories(_ values: (String, JSON)) -> Repository? {
    return try? Repository(values.1)
}

private func repositoryGraph(named name: String, owner: String) -> GraphQL {
    return .children(Node("repository", alias: alias(owner: owner, repositoryName: name), ["owner": owner, "name": name]), {
        [.values(["name"]),
         .children(Node("issues", ["first": 10, "states": GraphQLArray(["OPEN"])]), {
             return [.children(Node("nodes"), {
                 [.values(["title", "id"])]
             })]
         })]
    })

}

private func alias(owner: String, repositoryName: String) -> String {
    return "\(owner)_\(repositoryName)"
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
