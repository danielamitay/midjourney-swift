//
//  Midjourney+WebSocket.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 1/12/24.
//

import Combine
import Foundation

public struct WSJob {
    let id: String
    let enqueue_time: Int
    let width: Int
    let height: Int
}

public struct WSJobUpdate {
    struct Img: Codable {
        let data: String
    }
    let id: String
    let percentage_complete: Int
    let imgs: [Img]?
}

public protocol WebSocketDelegate {
    func jobCreated(_ job: WSJob)
    func jobUpdate(_ job: WSJobUpdate)
}

public final class WebSocket {
    // Initializer arguments
    public var delegate: WebSocketDelegate?
    private let userId: String
    private let webToken: String

    // Internal state
    private var webSocketTask: URLSessionWebSocketTask? = nil
    private var pingTimer: Timer? = nil

    init(delegate: WebSocketDelegate? = nil, userId: String, webToken: String) {
        self.delegate = delegate
        self.userId = userId
        self.webToken = webToken
    }

    // Connect to the WebSocket
    public func connect() {
        guard let url = URL(string: "wss://ws.midjourney.com/ws") else { return }
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()

        // Receive messages
        receiveMessage()

        // Subscribe to user
        subscribeToUser(webToken)

        // Start a timer for ping messages
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true, block: { [weak self] _ in
            self?.sendPing()
        })
    }

    // Disconnect the WebSocket
    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

public extension WebSocket {
    func subscribeToJob(_ jobId: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let roomId = "singleplayer_\(userId)"
        let message = WebSocketMessage.subscribeToJob(jobId: jobId, roomId: roomId)
        if let subscribeData = try? JSONEncoder().encode(message) {
            let message = URLSessionWebSocketTask.Message.data(subscribeData)
            webSocketTask?.send(message, completionHandler: { err in
                guard let completion else { return }
                if let err {
                    completion(.failure(err))
                } else {
                    completion(.success(()))
                }
            })
        }
    }

    func subscribeToJobAsync(_ jobId: String) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            subscribeToJob(jobId) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private extension WebSocket {
    // Receive messages from the WebSocket
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8), let message = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                        self?.onSocketMessage(message)
                    }
                case .data(let data):
                    if let message = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                        self?.onSocketMessage(message)
                    }
                default:
                    break
                }
                // Continue receiving messages
                self?.receiveMessage()
            }
        }
    }

    private func onSocketMessage(_ message: WebSocketMessage) {
        switch message {
        case .roomNewJob(_, let job):
            let createdJob = WSJob(id: job.id, enqueue_time: job.enqueue_time, width: job.width, height: job.height)
            delegate?.jobCreated(createdJob)
        case .jobProgress(let data, let jobId, let roomId):
            let updatedJob = WSJobUpdate(
                id: jobId,
                percentage_complete: data.percentage_complete,
                imgs: data.imgs?.compactMap {
                    return WSJobUpdate.Img(data: $0.data)
                }
            )
            delegate?.jobUpdate(updatedJob)
        default:
            break
        }
    }
}

private extension WebSocket {
    func sendPing() {
        let message = WebSocketMessage.ping
        if let pingData = try? JSONEncoder().encode(message) {
            let message = URLSessionWebSocketTask.Message.data(pingData)
            webSocketTask?.send(message, completionHandler: { _ in
                // no-op
            })
        }
    }

    func subscribeToUser(_ jwt: String) {
        let message = WebSocketMessage.subscribeToUser(jwt: webToken)
        if let subscribeData = try? JSONEncoder().encode(message) {
            let message = URLSessionWebSocketTask.Message.data(subscribeData)
            webSocketTask?.send(message, completionHandler: { _ in
                // no-op
            })
        }
    }
}

// MARK: Message formats

fileprivate enum WebSocketMessage: Codable {
    case subscribeToUser(jwt: String)
    case userSuccess(userId: String)
    case listOfUsers(roomId: String, users: [User])
    case ping
    case roomNewJob(roomId: String, job: Job)
    case jobSuccess(jobId: String)
    case jobProgress(data: JobProgressData, jobId: String, roomId: String)
    case subscribeToJob(jobId: String, roomId: String)

    enum MessageType: String, Codable {
        case subscribeToUser = "subscribe_to_user"
        case userSuccess = "user_success"
        case listOfUsers = "list_of_users"
        case ping
        case roomNewJob = "room_new_job"
        case jobSuccess = "job_success"
        case jobProgress = "job_progress"
        case subscribeToJob = "subscribe_to_job"
    }

    enum CodingKeys: String, CodingKey {
        case type
        case jwt
        case userId = "user_id"
        case roomId = "room_id"
        case users
        case job
        case data
        case jobId = "job_id"
    }

    struct User: Codable {
        let user_id: String
        let username: String
        let isTyping: Bool
    }

    struct Job: Codable {
        let id: String
        let event_type: String
        let enqueue_time: Int
        let width: Int
        let height: Int
        let username: String
    }

    struct JobProgressData: Codable {
        enum Status: String, Codable {
            case unqueue
            case running
            case completed
        }
        struct Img: Codable {
            let data: String
        }

        let current_status: Status
        let percentage_complete: Int
        let imgs: [Img]?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .subscribeToUser:
            let jwt = try container.decode(String.self, forKey: .jwt)
            self = .subscribeToUser(jwt: jwt)
        case .userSuccess:
            let userId = try container.decode(String.self, forKey: .userId)
            self = .userSuccess(userId: userId)
        case .listOfUsers:
            let roomId = try container.decode(String.self, forKey: .roomId)
            let users = try container.decode([User].self, forKey: .users)
            self = .listOfUsers(roomId: roomId, users: users)
        case .ping:
            self = .ping
        case .roomNewJob:
            let roomId = try container.decode(String.self, forKey: .roomId)
            let job = try container.decode(Job.self, forKey: .job)
            self = .roomNewJob(roomId: roomId, job: job)
        case .jobSuccess:
            let jobId = try container.decode(String.self, forKey: .jobId)
            self = .jobSuccess(jobId: jobId)
        case .jobProgress:
            let data = try container.decode(JobProgressData.self, forKey: .data)
            let jobId = try container.decode(String.self, forKey: .jobId)
            let roomId = try container.decode(String.self, forKey: .roomId)
            self = .jobProgress(data: data, jobId: jobId, roomId: roomId)
        case .subscribeToJob:
            let jobId = try container.decode(String.self, forKey: .jobId)
            let roomId = try container.decode(String.self, forKey: .roomId)
            self = .subscribeToJob(jobId: jobId, roomId: roomId)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .subscribeToUser(let jwt):
            try container.encode(MessageType.subscribeToUser.rawValue, forKey: .type)
            try container.encode(jwt, forKey: .jwt)
        case .userSuccess(let userId):
            try container.encode(MessageType.userSuccess.rawValue, forKey: .type)
            try container.encode(userId, forKey: .userId)
        case .listOfUsers(let roomId, let users):
            try container.encode(MessageType.listOfUsers.rawValue, forKey: .type)
            try container.encode(roomId, forKey: .roomId)
            try container.encode(users, forKey: .users)
        case .ping:
            try container.encode(MessageType.ping.rawValue, forKey: .type)
        case .roomNewJob(let roomId, let job):
            try container.encode(MessageType.roomNewJob.rawValue, forKey: .type)
            try container.encode(roomId, forKey: .roomId)
            try container.encode(job, forKey: .job)
        case .jobSuccess(let jobId):
            try container.encode(MessageType.jobSuccess.rawValue, forKey: .type)
            try container.encode(jobId, forKey: .jobId)
        case .jobProgress(let data, let jobId, let roomId):
            try container.encode(MessageType.jobProgress.rawValue, forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encode(jobId, forKey: .jobId)
            try container.encode(roomId, forKey: .roomId)
        case .subscribeToJob(let jobId, let roomId):
            try container.encode(MessageType.subscribeToJob.rawValue, forKey: .type)
            try container.encode(jobId, forKey: .jobId)
            try container.encode(roomId, forKey: .roomId)
        }
    }
}
