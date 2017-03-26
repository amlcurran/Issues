import UIKit

class ViewController: UIViewController {

    let repository = IssuesRepository()

    override func viewDidLoad() {
        super.viewDidLoad()
        repository.issues({ issues in
            print("We've got issues!: \(issues)")
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class IssuesRepository {

    func issues(_ completion: @escaping ((Issues) -> Void)) {
        let graph = "query { repository(owner: \"amlcurran\", name: \"Social\") { issues(first: 10, states: [OPEN]) { nodes { title } } } }"
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
            if let data = json["data"] as? [String: Any],
               let repository = data["repository"] as? [String: Any],
               let issuesJson = repository["issues"] as? [String: Any],
               let nodes = issuesJson["nodes"] as? [[String: Any]] {
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

    init(_ jsonNode: [[String: Any]]) throws {
        results = jsonNode.flatMap({ issueJSON in
            return try? Issue(issueJSON)
        })
    }
}

struct Issue: JSONResponse {
    let title: String

    init(_ jsonNode: [String: Any]) throws {
        guard let title = jsonNode["title"] as? String else {
            throw ParseError.missingKey
        }
        self.title = title
    }
}

protocol JSONArrayResponse {
    init(_ jsonNode: [[String: Any]]) throws
}

protocol JSONResponse {
    init(_ jsonNode: [String: Any]) throws
}

enum ParseError: Error {
    case missingKey
}
