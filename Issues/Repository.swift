import Foundation
import SwiftyJSON

struct Repository: JSONResponse {
    
    let name: String
    let issues: [Issue]
    
    init(_ jsonNode: JSON) throws {
        guard let name = jsonNode["name"].string,
            let issuesNode = jsonNode["issues"]["nodes"].array else {
                throw ParseError.invalidJSON(json: jsonNode)
        }
        self.name = name
        self.issues = issuesNode.flatMap({ issueJSON in
            return try? Issue(issueJSON)
        })
    }
    
}
