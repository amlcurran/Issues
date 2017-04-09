import UIKit

class IssueCell: UITableViewCell {
    
    let title = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "issue")
        layout()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layout()
    }
    
    func layout() {
        contentView.addSubview(title)
        title.constrainToSuperview([.leading, .trailing], insetBy: 16)
        title.constrainToSuperview([.top, .bottom], insetBy: 12)
    }
    
    func style() {
        title.numberOfLines = 0
    }
    
    func bind(to issue: Issue) {
        title.text = issue.title
    }
    
}
