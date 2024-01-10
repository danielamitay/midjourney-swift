//
//  Midjourney+Auth.swift
//  midjourney-swift
//
//  Created by Daniel Amitay on 12/22/23.
//

import Foundation

import Alamofire

public extension Midjourney {
    struct UserInfo: Codable, Identifiable {
        public var id: String {
            return user_id
        }
        public let user_id: String
        public let username: String
    }
}

// MARK: Urls

internal extension Midjourney.UserInfo {
    static let userInfoUrl = "https://www.midjourney.com/explore"
}

// MARK: Response formats

internal extension Midjourney {
    struct AuthResponse: Decodable {
        struct AuthProperties: Decodable {
            struct AuthUser: Decodable {
                struct UserAbilities: Decodable {
                    let web_tester: Bool?
                }
                let midjourney_id: String
                let displayName: String
                let websocketAccessToken: String
                let abilities: UserAbilities
            }
            let initialAuthUser: AuthUser
        }
        let props: AuthProperties
    }
    enum AuthError: Error {
        case unknown
    }
}

// MARK: Helpers

internal extension Midjourney {
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

internal extension String {
    func stringBetween(start: String, end: String) -> String? {
        guard let startRange = self.range(of: start),
              let endRange = self.range(of: end, range: startRange.upperBound..<self.endIndex) else {
            return nil
        }
        let range = startRange.upperBound..<endRange.lowerBound
        return String(self[range])
    }
}
