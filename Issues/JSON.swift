//
//  JSON.swift
//  Issues
//
//  Created by Alex Curran on 27/03/2017.
//  Copyright © 2017 Alex Curran. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSONSerialization {
    
    static func json(from data: Data) throws -> JSON {
        if let jsonAny = try? JSONSerialization.jsonObject(with: data),
            let json = jsonAny as? JSON {
            return json
        }
        throw ParseError.noJSON
    }
    
}

protocol JSONResponse {
    init(_ jsonNode: JSON) throws
}

enum ParseError: Error {
    case missingKey
    case noJSON
    case invalidJSON(json: JSON)
    case badResponse(response: URLResponse?)
}
