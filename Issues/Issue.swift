import Foundation
import SwiftyJSON

struct Issue: JSONResponse {
    let title: String
    
    init(_ jsonNode: JSON) throws {
        guard let title = jsonNode["title"].string else {
            throw ParseError.invalidJSON(json: jsonNode)
        }
        self.title = title
    }
}
