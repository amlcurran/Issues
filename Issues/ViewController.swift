import UIKit

class ViewController: UIViewController {
    
    let repository = IssuesRepository(resultQueue: .main)
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
        repository.issues(
            onResult: { [weak self] issues in
                self?.source.update(issues.results)
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

class IssueCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "issue")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
