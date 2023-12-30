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

// MARK: User Info

public extension Midjourney {
    func userInfo(complete: @escaping (Result<UserInfo, Error>) -> Void) {
        AF.request(
            Midjourney.UserInfo.userInfoUrl,
            method: .get,
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
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

    func userInfoAsync() async throws -> UserInfo {
        return try await withCheckedThrowingContinuation { continuation in
            userInfo() { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: Jobs

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
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
        )
        .validate()
        .responseDecodable(of: RecentJobsResponse.self) { response in
            complete(response.result.map { $0.jobs }.mapError { $0 as Error})
        }
    }

    func recentJobsAsync(page: Int = 0, pageSize: Int = 60) async throws -> [Job] {
        return try await withCheckedThrowingContinuation { continuation in
            recentJobs(page: page, pageSize: pageSize) { result in
                continuation.resume(with: result)
            }
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
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
        )
        .validate()
        .responseDecodable(of: UserJobsResponse.self) { response in
            complete(response.result.map { $0.data }.mapError { $0 as Error})
        }
    }

    func userJobsAsync(_ userId: String, cursor: String? = nil, pageSize: Int = 1000) async throws -> [Job] {
        return try await withCheckedThrowingContinuation { continuation in
            userJobs(userId, cursor: cursor, pageSize: pageSize) { result in
                continuation.resume(with: result)
            }
        }
    }

    func jobsStatus(_ jobIds: [String], complete: @escaping (Result<[Job], Error>) -> Void) {
        let parameters: Parameters = [
            "jobIds": jobIds,
        ]
        AF.request(
            Midjourney.Job.jobStatusUrl,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding(destination: .httpBody),
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
        )
        .validate()
        .responseDecodable(of: [Job].self) { response in
            complete(response.result.mapError { $0 as Error})
        }
    }

    func jobsStatusAsync(_ jobIds: [String]) async throws -> [Job] {
        return try await withCheckedThrowingContinuation { continuation in
            jobsStatus(jobIds) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: Likes

public extension Midjourney {
    func likedJobs(page: Int = 0, complete: @escaping (Result<[Job], Error>) -> Void) {
        let parameters: Parameters = [
            "page": page,
            "_ql": "explore",
        ]
        AF.request(
            Midjourney.Job.likedJobsUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
        )
        .validate()
        .responseDecodable(of: LikedJobsResponse.self) { response in
            complete(response.result.map { $0.jobs }.mapError { $0 as Error})
        }
    }

    func likedJobsAsync(page: Int = 0) async throws -> [Job] {
        return try await withCheckedThrowingContinuation { continuation in
            likedJobs(page: page) { result in
                continuation.resume(with: result)
            }
        }
    }

    func likeJob(_ jobId: String, _ value: Bool, complete: @escaping (Result<Void, Error>) -> Void) {
        let parameters: Parameters = [
            "value": (value ? "true" : "false"),
        ]
        AF.request(
            Midjourney.Job.likeJobUrl(jobId),
            method: .post,
            parameters: parameters,
            encoding: URLEncoding(destination: .queryString),
            headers: requestHeaders,
            // A simple retry policy for this idempotent request
            interceptor: ConnectionLostRetryPolicy()
        )
        .validate()
        .responseData { response in
            switch response.result {
            case .success(_):
                complete(.success(()))
            case .failure(let error):
                complete(.failure(error as Error))
            }
        }
    }

    func likeJobAsync(_ jobId: String, _ value: Bool) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            likeJob(jobId, value) { result in
                continuation.resume(with: result)
            }
        }
    }
}
