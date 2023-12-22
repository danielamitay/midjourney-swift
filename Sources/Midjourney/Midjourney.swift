//
//  Midjourney.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 12/20/23.
//

import Foundation

import Alamofire

public struct Midjourney {
    internal let cookie: String
    public init(cookie: String) {
        self.cookie = cookie
    }
}

public extension Midjourney {
    func userInfo(complete: @escaping (Result<UserInfo, Error>) -> Void) {
        AF.request(
            Midjourney.UserInfo.userInfoUrl,
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
                        let authUser = authResponse.props.initialAuthUser
                        let userInfo = UserInfo(user_id: authUser.midjourney_id, username: authUser.displayName)
                        complete(.success(userInfo))
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
    func recentJobs(page: Int = 0, pageSize: Int = 60, complete: @escaping (Result<[Job], Error>) -> Void) {
        let parameters: Parameters = [
            "amount": pageSize,
            "page": page,
            "feed": "top_recent_jobs",
            "_ql": "explore",
        ]
        AF.request(
            Midjourney.Job.recentJobsUrl,
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

    func userJobs(_ userId: String, cursor: String? = nil, pageSize: Int = 1000, complete: @escaping (Result<[Job], Error>) -> Void) {
        var parameters: Parameters = [
            "user_id": userId,
            "page_size": pageSize,
        ]
        if let cursor {
            parameters["cursor"] = cursor
        }
        AF.request(
            Midjourney.Job.userJobsUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: requestHeaders
        )
        .validate()
        .responseDecodable(of: UserJobsResponse.self) { response in
            complete(response.result.map { $0.data }.mapError { $0 as Error})
        }
    }
}
