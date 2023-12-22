//
//  Midjourney.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 12/20/23.
//

import Alamofire
import Foundation

public struct Midjourney {
    private let cookie: String
    public init(cookie: String) {
        self.cookie = cookie
    }
}

public extension Midjourney {
    private struct AuthResponse: Decodable {
        struct AuthProperties: Decodable {
            struct AuthUser: Decodable {
                let midjourney_id: String
                let displayName: String
            }
            let initialAuthUser: AuthUser
        }
        let props: AuthProperties
    }
    private enum AuthError: Error {
        case unknown
    }

    func myUserId(complete: @escaping (Result<String, Error>) -> Void) {
        let requestUrl = "https://www.midjourney.com/explore"
        AF.request(
            requestUrl,
            method: .get,
            headers: requestHeaders
        )
        .validate()
        .responseString(encoding: .utf8) { response in
            switch response.result {
            case .success(let html):
                let jsonString = html.stringBetween(start: "<script id=\"__NEXT_DATA__\" type=\"application/json\">", end: "</script>")
                if let jsonString, let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: jsonData)
                        complete(.success(authResponse.props.initialAuthUser.midjourney_id))
                    } catch {
                        complete(.failure(error))
                    }
                } else {
                    complete(.failure(AuthError.unknown))
                }
            case .failure(let failure):
                complete(.failure(failure))
            }
        }
    }
}

public extension Midjourney {
    private struct RecentJobsResponse: Decodable {
        let type: String
        let jobs: [Job]
    }

    func recentJobs(page: Int = 0, pageSize: Int = 60, complete: @escaping (Result<[Job], Error>) -> Void) {
        let requestUrl = "https://www.midjourney.com/api/app/recent-jobs"
        let parameters: Parameters = [
            "amount": pageSize,
            "page": page,
            "feed": "top_recent_jobs",
            "_ql": "explore",
        ]
        AF.request(
            requestUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: requestHeaders
        )
        .validate()
        .responseDecodable(of: RecentJobsResponse.self) { response in
            complete(response.result.map { $0.jobs }.mapError { $0 as Error})
        }
    }

    private struct MyJobsResponse: Decodable {
        let checkpoint: String?
        let cursor: String
        let data: [Job]
    }

    func myJobs(userId: String, cursor: String? = nil, pageSize: Int = 1000, complete: @escaping (Result<[Job], Error>) -> Void) {
        let requestUrl = "https://www.midjourney.com/api/pg/thomas-jobs"
        var parameters: Parameters = [
            "user_id": userId,
            "page_size": pageSize,
        ]
        if let cursor {
            parameters["cursor"] = cursor
        }
        AF.request(
            requestUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: requestHeaders
        )
        .validate()
        .responseDecodable(of: MyJobsResponse.self) { response in
            complete(response.result.map { $0.data }.mapError { $0 as Error})
        }
    }
}

private extension Midjourney {
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
            "Referer": "https://www.midjourney.com/explore",
            "Referrer-Policy": "origin-when-cross-origin",
            "cookie": cookie,
        ].compactMap { (key: String, value: String) in
                .init(name: key, value: value)
        }
        return .init(headers)
    }
}

private extension String {
    func stringBetween(start: String, end: String) -> String? {
        guard let startRange = self.range(of: start),
              let endRange = self.range(of: end, range: startRange.upperBound..<self.endIndex) else {
            return nil
        }
        let range = startRange.upperBound..<endRange.lowerBound
        return String(self[range])
    }
}
