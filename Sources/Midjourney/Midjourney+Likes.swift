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
    static func likeJobUrl(_ jobId: String) -> String {
        return "https://www.midjourney.com/api/jobs/\(jobId)/like"
    }
}

// MARK: Response formats

internal extension Midjourney {
    struct LikedJobsResponse: Decodable {
        let jobs: [Job]
    }
}
