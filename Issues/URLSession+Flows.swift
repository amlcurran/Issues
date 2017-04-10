//
//  URLSession+Flows.swift
//  Issues
//
//  Created by Alex Curran on 10/04/2017.
//  Copyright © 2017 Alex Curran. All rights reserved.
//

import Foundation

extension URLSession {
    
    func dataTask(with request: URLRequest, onSuccess: @escaping ((Data, URLResponse?) -> Void), onError: @escaping ((Error, URLResponse?) -> Void)) -> URLSessionDataTask {
        return dataTask(with: request, completionHandler: { (maybeData, maybeResponse, maybeError) in
            if let data = maybeData {
                onSuccess(data, maybeResponse)
            } else if let error = maybeError {
                onError(error, maybeResponse)
            } else {
                preconditionFailure("Data task did not contain data or an error")
            }
        })
    }
    
}
