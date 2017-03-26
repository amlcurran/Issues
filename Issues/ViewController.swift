import UIKit

class ViewController: UIViewController {

    let repository = IssuesRepository()
    let tableView = UITableView()
    let source = Source<Issue, IssueCell>(binding: { cell, issue in
        cell.textLabel?.text = issue.title
    })

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.constrainToSuperview([.leading, .trailing, .top, .bottom])

        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        tableView.register(IssueCell.self, forCellReuseIdentifier: "issue")

        tableView.dataSource = source
        repository.issues({ [weak self] issues in
            DispatchQueue.main.async { [weak self] in
                self?.source.update(issues.results)
                self?.tableView.reloadData()
            }
            print("We've got issues!: \(issues)")
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class Source<Data, Cell: UITableViewCell>: NSObject, UITableViewDataSource {

    private let binding: ((Cell, Data) -> Void)
    private var issues: [Data] = []

    init(binding: @escaping ((Cell, Data) -> Void)) {
        self.binding = binding
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issues.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let basicCell = tableView.dequeueReusableCell(withIdentifier: "issue", for: indexPath)
        guard let cell = basicCell as? Cell else {
            preconditionFailure("Expected cell dequeued for issue to be \(Cell.self) but was \(type(of: basicCell))")
        }
        binding(cell, issues[indexPath.row])
        return cell
    }

    func update(_ issues: [Data]) {
        self.issues = issues
    }

}

class IssueCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "issue")
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
