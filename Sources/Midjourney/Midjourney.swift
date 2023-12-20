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

    init(cookie: String) {
        self.cookie = cookie
    }
}

extension Midjourney {
    private struct AuthResponse: Decodable {
        struct AuthProperties: Decodable {
            struct AuthUser: Decodable {
                let midjourney_id: String
            }
            let initialAuthUser: AuthUser
        }
        let props: AuthProperties
    }
    private enum AuthError: Error {
        case unknown
    }

    func myUserId(complete: @escaping (Result<String, Error>) -> Void) {
        let headers: [HTTPHeader] = [
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "cache-control": "no-cache",
            "pragma": "no-cache",
            "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
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
        let requestUrl = "https://www.midjourney.com/explore"
        AF.request(
            requestUrl,
            method: .get,
            headers: .init(headers)
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

fileprivate extension String {
    func stringBetween(start: String, end: String) -> String? {
        guard let startRange = self.range(of: start),
              let endRange = self.range(of: end, range: startRange.upperBound..<self.endIndex) else {
            return nil
        }
        let range = startRange.upperBound..<endRange.lowerBound
        return String(self[range])
    }
}

