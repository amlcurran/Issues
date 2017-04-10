//
//  JSON.swift
//  Issues
//
//  Created by Alex Curran on 27/03/2017.
//  Copyright © 2017 Alex Curran. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol JSONResponse {
    init(_ jsonNode: JSON) throws
}

enum ParseError: Error {
    case missingKey
    case noJSON
    case invalidJSON(json: JSON)
    case badResponse(response: URLResponse?)
}
