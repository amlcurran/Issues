import Foundation
import UIKit

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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "What's on"
    }

}
