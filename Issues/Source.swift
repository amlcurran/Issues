import Foundation
import UIKit

class Source<Cell: UITableViewCell>: NSObject, UITableViewDataSource, UITableViewDelegate {

    private let binding: ((Cell, IssueTableModel) -> Void)
    private var repositories: [Repository] = []

    init(binding: @escaping ((Cell, IssueTableModel) -> Void)) {
        self.binding = binding
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories[section].tableModelIssueCount
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return repositories.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let basicCell = tableView.dequeueReusableCell(withIdentifier: "issue", for: indexPath)
        guard let cell = basicCell as? Cell else {
            preconditionFailure("Expected cell dequeued for issue to be \(Cell.self) but was \(type(of: basicCell))")
        }
        binding(cell, repositories[indexPath.section].issueModel(for: indexPath))
        return cell
    }

    func update(_ repositories: [Repository]) {
        self.repositories = repositories
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return repositories[section].name
    }

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return repositories[indexPath.section].issueModel(for: indexPath).isEnabled ? indexPath : nil
    }


}

private extension Repository {

    var tableModelIssueCount: Int {
        if issues.count == 0 {
            return 1
        } else {
            return issues.count
        }
    }

}

private extension Repository {

    func issueModel(for indexPath: IndexPath) -> IssueTableModel {
        if issues.count == 0 {
            return IssueTableModel(title: "No issues", isEnabled: false)
        } else {
            return IssueTableModel(title: issues[indexPath.row].title, isEnabled: true)
        }
    }

}

struct IssueTableModel {

    let title: String
    let isEnabled: Bool

}
