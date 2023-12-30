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

    struct ParsedCommand {
        public struct Parameter: Identifiable {
            public var id: String {
                return "--\(name) \(value)"
            }
            public let name: String
            public let value: String
        }
        public let prompt: String
        public let parameters: [Parameter]
    }

    // Whether this job is a grid or just one image
    var jobType: JobType {
        if let parent_id, let parent_grid {
            return .image(parent_id, parent_grid)
        }
        return .grid
    }

    var parsedCommand: ParsedCommand {
        let components = full_command.components(separatedBy: "--")
        let prompt = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var parameters: [ParsedCommand.Parameter] = []
        components.dropFirst().forEach { component in
            let pair = component.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if pair.count == 2 {
                let key = String(pair[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(pair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                parameters.append(.init(name: key, value: value))
            }
        }
        return .init(prompt: prompt, parameters: parameters)
    }

    var aspectRatio: CGFloat {
        return CGFloat(width) / CGFloat(height)
    }

    var enqueueDate: Date {
        return Midjourney.Job.enqueueDateFormatter.date(from: enqueue_time) ?? .distantPast
    }

    struct Image: Identifiable {
        public let id: String
        public let parent_id: String
        public let parent_grid: Int
        public let width: Int
        public let height: Int

        public init(id: String, parent_id: String, parent_grid: Int, width: Int, height: Int) {
            self.id = id
            self.parent_id = parent_id
            self.parent_grid = parent_grid
            self.width = width
            self.height = height
        }

        public var aspectRatio: CGFloat {
            return CGFloat(width) / CGFloat(height)
        }
    }

    var images: [Image] {
        switch jobType {
        case .grid:
            return (0..<batch_size).map { grid_id in
                return Image(
                    // Generate an id that is consistent across generations/fetches
                    id: "\(id)_\(grid_id)",
                    parent_id: id,
                    parent_grid: grid_id,
                    width: width / 2,
                    height: height / 2
                )
            }
        case .image(let parent_id, let parent_grid):
            return [Image(
                id: id,
                parent_id: parent_id,
                parent_grid: parent_grid,
                width: width,
                height: height
            )]
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
    static let jobStatusUrl = "https://www.midjourney.com/api/app/job-status"
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

// MARK: Helpers

internal extension Midjourney.Job {
    static let enqueueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
