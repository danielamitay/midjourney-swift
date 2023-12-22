//
//  Midjourney+Jobs.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 12/22/23.
//

import Foundation

public extension Midjourney {
    struct Job: Codable, Identifiable {
        public let id: String

        // Properties seen on all jobs
        public let enqueue_time: String
        public let job_type: String
        public let event_type: String
        public let full_command: String
        public let batch_size: Int
        public let width: Int
        public let height: Int

        // Properties only seen on public jobs/images
        public let parent_grid: Int?
        public let parent_id: String?
        public let username: String?
        public let user_id: String?
    }
}

// MARK: Urls

internal extension Midjourney.Job {
    static let recentJobsUrl = "https://www.midjourney.com/api/app/recent-jobs"
    static let userJobsUrl = "https://www.midjourney.com/api/app/recent-jobs"
}

// MARK: Response formats

internal extension Midjourney {
    struct RecentJobsResponse: Decodable {
        let type: String
        let jobs: [Job]
    }
    struct UserJobsResponse: Decodable {
        let checkpoint: String?
        let cursor: String
        let data: [Job]
    }
}
