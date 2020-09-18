//
//  Networking.swift
//  Networking
//
//  Created by Simon-Pierre Roy on 9/22/19.
//  Copyright © 2019 Wayfair. All rights reserved.
//

import Foundation
import Combine
import KasaCore

public enum Networking {
    
    enum HTTP: String {
        case post = "POST"
        case get = "GET"
    }
    
    public typealias DataFetcher = AnyPublisher<Data, Error>
    public typealias ModelFetcher<Model: Decodable> = AnyPublisher<Model, Error>
    static let defaultWorkQueue = DispatchQueue(label: "Networking.defaultWorkQueue", qos: .userInitiated, attributes: .concurrent)
    
    static func fetcher(urlSession: URLSession, urlResquest: URLRequest, workQueue: DispatchQueue = defaultWorkQueue) -> DataFetcher {
        return urlSession.dataTaskPublisher(for: urlResquest)
            .receive(on: workQueue)
            .tryMap { data, reponse in
                if let httpResponse = reponse as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    throw CodeError(statusCode: httpResponse.statusCode)
                }
                return data
            }
            .eraseToAnyPublisher()
    }
    
    static func modelFetcher<Model: Decodable>(decoder: JSONDecoder, fetcher: DataFetcher) -> ModelFetcher<Model> {
        return fetcher.tryMap {
            do {
                return try decoder.decode(Model.self, from: $0)
            } catch  {
                throw ModelError(decodeError: error)
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func modelFetcher<Model: Decodable>(
        urlSession: URLSession,
        urlResquest: URLRequest,
        decoder: JSONDecoder,
        workQueue: DispatchQueue = defaultWorkQueue
    ) -> ModelFetcher<Model> {
        let dataFetcher = fetcher(urlSession: urlSession, urlResquest: urlResquest, workQueue: workQueue)
        return modelFetcher(decoder: decoder, fetcher: dataFetcher)
    }
    
    
    static let guaranteeHeaders = mver(^\URLRequest.allHTTPHeaderFields) { $0 = $0 ?? [:] }
    
    static let setHeader = { name, value in
        mver(^\URLRequest.allHTTPHeaderFields) { $0?[name] = value }
    }
    
    static let setHeaders = { (headers: [String: String]) in
        mver(^\URLRequest.allHTTPHeaderFields) { request in headers.forEach { (k,v) in request?[k] = v } }
    }
    
    static func setQuery(items: [String: String]) -> (URL) -> URL? {
        { url in
            Optional.some(url)
                .flatMap(URLComponents.from(url:))
                .map { old in
                    var new = old
                    new.queryItems = items.map(URLQueryItem.init(name:value:))
                    return new
                }.flatMap(^\URLComponents.url)
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

struct ModelError: LocalizedError {
    let decodeError: Error
    
    var errorDescription: String? {
        return "Invalid data from the request."
    }
}
