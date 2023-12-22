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
        public let parent_id: String?
        public let parent_grid: Int?
        public let user_id: String?
        public let username: String?
    }
}

public extension Midjourney.Job {
    enum JobType {
        case grid
        case image(String, Int)
    }

    // Whether this job is a grid or just one image
    var jobType: JobType {
        if let parent_id, let parent_grid {
            return .image(parent_id, parent_grid)
        }
        return .grid
    }

    struct Image {
        public let id: String
        public let parent_id: String
        public let parent_grid: Int
    }

    var images: [Image] {
        switch jobType {
        case .grid:
            return (0..<batch_size).map { idx in
                // Generate an id that is consistent across generations/fetches
                let uuid: String = "\(id)_\(idx)"
                return Image(id: UUID().uuidString, parent_id: id, parent_grid: idx)
            }
        case .image(let parent_id, let parent_grid):
            let image: Image = .init(id: id, parent_id: parent_id, parent_grid: parent_grid)
            return [image]
        }
    }
}

public extension Midjourney.Job.Image {
    enum Format: String {
        case png
        case webp
    }

    func fullImageUrl(format: Format = .png) -> String {
        return "https://cdn.midjourney.com/\(parent_id)/0_\(parent_grid).\(format.rawValue)"
    }

    enum Size {
        case full   // Full image
        case large  // 640px
        case medium // 384px
        case small  // 128px
        case tiny   // 32px

        internal var modifier: String {
            switch self {
            case .full:
                return "_2048_N"
            case .large:
                return "_640_N"
            case .medium:
                return "_384_N"
            case .small:
                return "_128_N"
            case .tiny:
                return "_32_N"
            }
        }
    }

    func webpImageUrl(size: Size = .large, quality: Int? = nil) -> String {
        let queryParams = if let quality { "?method=shortest&quality=\(quality)" } else { "" }
        return "https://cdn.midjourney.com/\(parent_id)/0_\(parent_grid)\(size.modifier).webp\(queryParams)"
    }
}

// MARK: Urls

internal extension Midjourney.Job {
    static let recentJobsUrl = "https://www.midjourney.com/api/app/recent-jobs"
    static let userJobsUrl = "https://www.midjourney.com/api/pg/thomas-jobs"
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
