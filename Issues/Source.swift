import Foundation
import UIKit

class Source<Cell: UITableViewCell>: NSObject, UITableViewDataSource {

    private let binding: ((Cell, Issue) -> Void)
    private var repositories: [Repository] = []

    init(binding: @escaping ((Cell, Issue) -> Void)) {
        self.binding = binding
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories[section].issues.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return repositories.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let basicCell = tableView.dequeueReusableCell(withIdentifier: "issue", for: indexPath)
        guard let cell = basicCell as? Cell else {
            preconditionFailure("Expected cell dequeued for issue to be \(Cell.self) but was \(type(of: basicCell))")
        }
        binding(cell, repositories[indexPath.section].issues[indexPath.row])
        return cell
    }

    func update(_ respository: [Repository]) {
        self.repositories = respository
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return repositories[section].name
    }

}
