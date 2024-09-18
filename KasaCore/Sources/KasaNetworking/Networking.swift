//
//  Networking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//

import Foundation
import KasaCore

public enum Networking {

    public enum HTTP: String {
        case post = "POST"
        case get = "GET"
    }

    private static let defaultWorkQueue = DispatchQueue(
        label: "Networking.defaultWorkQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private static func fetcher(
        urlSession: URLSession,
        urlRequest: URLRequest,
        workQueue: DispatchQueue = defaultWorkQueue
    ) async throws -> Data {
        let (data, response) = try await urlSession.data(for: urlRequest, delegate: nil)
        guard let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) else {
            return data
        }
        throw CodeError(statusCode: httpResponse.statusCode)
    }

    static func modelFetcher<Model: Decodable>(
        decoder: JSONDecoder,
        urlSession: URLSession,
        urlRequest: URLRequest,
        workQueue: DispatchQueue = defaultWorkQueue
    ) async throws -> Model {
        let data = try await fetcher(urlSession: urlSession, urlRequest: urlRequest, workQueue: workQueue)
        return try decoder.decode(Model.self, from: data)
    }
}

extension Networking {

    public struct RequestError: LocalizedError {
        public init(
            errorDescription: String
        ) {
            self.errorDescription = errorDescription
        }
        public var errorDescription: String?
    }

    public struct CodeError: LocalizedError {
        public let statusCode: Int

        public var errorDescription: String? {
            return "Request was not completed successfully (status code: \(self.statusCode))."
        }
    }
}
