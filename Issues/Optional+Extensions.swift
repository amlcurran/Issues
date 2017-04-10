//
//  Optional+Extensions.swift
//  Issues
//
//  Created by Alex Curran on 10/04/2017.
//  Copyright © 2017 Alex Curran. All rights reserved.
//

import Foundation

extension Optional {
    
    func required(orElseThrow error: Error) throws -> Wrapped {
        if let requirement = self {
            return requirement
        }
        throw error
    }
    
    func or(_ backup: Wrapped) -> Wrapped {
        if let realSelf = self {
            return realSelf
        } else {
            return backup
        }
    }
    
}
