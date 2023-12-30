//
//  Midjourney+Likes.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 12/29/23.
//

import Foundation

// MARK: Urls

internal extension Midjourney.Job {
    static let likedJobsUrl = "https://www.midjourney.com/api/pg/user-likes"
}

// MARK: Response formats

internal extension Midjourney {
    struct LikedJobsResponse: Decodable {
        let jobs: [Job]
    }
}
