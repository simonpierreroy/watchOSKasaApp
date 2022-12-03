//
//  Networking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//  Copyright © 2019 Wayfair. All rights reserved.
//

import Foundation
import KasaCore

public enum Networking {

    enum HTTP: String {
        case post = "POST"
        case get = "GET"
    }

    static let defaultWorkQueue = DispatchQueue(
        label: "Networking.defaultWorkQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    static func fetcher(
        urlSession: URLSession,
        urlResquest: URLRequest,
        workQueue: DispatchQueue = defaultWorkQueue
    ) async throws -> Data {
        let (data, response) = try await urlSession.data(for: urlResquest, delegate: nil)
        guard let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) else {
            return data
        }
        throw CodeError(statusCode: httpResponse.statusCode)
    }

    static func modelFetcher<Model: Decodable>(
        decoder: JSONDecoder,
        urlSession: URLSession,
        urlResquest: URLRequest,
        workQueue: DispatchQueue = defaultWorkQueue
    ) async throws -> Model {
        let data = try await fetcher(urlSession: urlSession, urlResquest: urlResquest, workQueue: workQueue)
        return try decoder.decode(Model.self, from: data)
    }

    static let guaranteeHeaders = mver(^\URLRequest.allHTTPHeaderFields) { $0 = $0 ?? [:] }

    static let setHeader = { name, value in
        mver(^\URLRequest.allHTTPHeaderFields) { $0?[name] = value }
    }

    static let setHeaders = { (headers: [String: String]) in
        mver(^\URLRequest.allHTTPHeaderFields) { request in headers.forEach { (k, v) in request?[k] = v } }
    }

    static func setQuery(items: [String: String]) -> (URL) -> URL? {
        { url in
            Optional.some(url)
                .flatMap(URLComponents.from(url:))
                .map { old in
                    var new = old
                    new.queryItems = items.map(URLQueryItem.init(name:value:))
                    return new
                }
                .flatMap(^\URLComponents.url)
        }
    }
}

extension Networking {

    struct ResquestError: LocalizedError {
        var errorDescription: String?
    }

    struct CodeError: LocalizedError {
        let statusCode: Int

        var errorDescription: String? {
            return "Request was not completed successfully (status code: \(self.statusCode))."
        }
    }
}
