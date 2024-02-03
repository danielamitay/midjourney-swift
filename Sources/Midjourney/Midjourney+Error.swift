//
//  Midjourney+Error.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 2/2/24.
//

import Foundation

import Alamofire

public extension Midjourney {
    // Use this function to determine whether or not the user should be logged out in response to an error
    static func errorIsUnauthorized(_ error: Error) -> Bool {
        if let afError = error as? AFError {
            return afError.responseCode == 401
        }
        return false
    }
}
