import UIKit

class ViewController: UIViewController {
    
    let repository = IssuesRepository(resultQueue: .main)
    let tableView = UITableView(frame: .zero, style: .grouped)
    let source = Source<IssueCell>(binding: { cell, issue in
        cell.bind(to: issue)
    })
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Issues"
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.constrainToSuperview([.leading, .trailing, .top, .bottom])
        
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(IssueCell.self, forCellReuseIdentifier: "issue")
        
        tableView.dataSource = source
        repository.issues(
            onResult: { [weak self] repositories in
                self?.source.update(repositories)
                self?.tableView.reloadData()
            },
            onError: { error in
                print(error)
            }
        )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
