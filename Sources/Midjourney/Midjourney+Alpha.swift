//
//  Midjourney+Alpha.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 1/9/23.
//

import Foundation

import Alamofire

public extension Midjourney {
    struct Alpha {
        internal let cookie: String
        internal let userId: String
        internal let webToken: String

        public init(cookie: String, userId: String, webToken: String) {
            self.cookie = cookie
            self.userId = userId
            self.webToken = webToken
        }
    }
}

public extension Midjourney.Alpha {
    struct SubmittedJob: Codable, Identifiable {
        public struct JobMeta: Codable {
            public let height: Int
            public let width: Int
            public let batch_size: Int
            public let full_command: String
        }
        public var id: String {
            return job_id
        }
        public let job_id: String
        public let is_queued: Bool
        public let meta: JobMeta
        public let optimisticJobIndex: Int
    }
}

// MARK: Urls

internal extension Midjourney.Alpha {
    static let userInfoUrl = "https://alpha.midjourney.com/explore"
    static let submitJobsUrl = "https://alpha.midjourney.com/api/app/submit-jobs"
}

// MARK: Response formats

internal extension Midjourney.Alpha {
    struct SubmitJobsResponse: Decodable {
        let success: [SubmittedJob]
        // let failure: []
    }
}

// MARK: Helpers

internal extension Midjourney.Alpha {
    var requestHeaders: HTTPHeaders {
        let headers: [HTTPHeader] = [
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "cache-control": "no-cache",
            "pragma": "no-cache",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-csrf-protection": "1",
            "Referrer-Policy": "origin-when-cross-origin",
            "cookie": cookie,
        ].compactMap { (key: String, value: String) in
                .init(name: key, value: value)
        }
        return .init(headers)
    }
}
