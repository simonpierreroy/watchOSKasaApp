//
//  JSONValue.swift
//  Kasa WatchKit Extension
//
//  Created by Simon-Pierre Roy on 6/7/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import Foundation

@dynamicMemberLookup
public enum JSONValue {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    indirect case array([JSONValue])
    indirect case object([String: JSONValue])
}

public extension JSONValue {
    subscript(dynamicMember key: JSONValue) -> JSONValue? {
        self[key]
    }
    
    subscript(_ key: JSONValue) -> JSONValue? {
        if case let .number(key) = key {
            return self[Int(key)]
        } else if case let .string(key) = key {
            return self[key]
        }
        return nil
    }
    
    subscript(_ index: Int) -> JSONValue? {
        guard case let .array(array) = self else {
            return nil
        }
        return array[index]
    }
    
    subscript(_ key: String) -> JSONValue? {
        guard case let .object(object) = self else {
            return nil
        }
        return object[key]
    }
}

extension JSONValue: Equatable, Hashable { }

extension JSONValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .number(let doubleValue):
            try container.encode(doubleValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .object(let objectValue):
            try container.encode(objectValue)
        }
    }
}

extension JSONValue: Decodable {
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        
        if singleValueContainer.decodeNil() {
            self = .null
        } else if let boolValue = try? singleValueContainer.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let doubleValue = try? singleValueContainer.decode(Double.self) {
            self = .number(doubleValue)
        } else if let stringValue = try? singleValueContainer.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? singleValueContainer.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? singleValueContainer.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: singleValueContainer,
                debugDescription: "invalid JSON structure or the input was not JSON")
        }
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(value)
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}


struct RawStringJSONContainer: Codable {
    
    static let rawEncoder = JSONEncoder()
    static let rawDecoder = JSONDecoder()
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try RawStringJSONContainer.rawEncoder.encode(self.wrapping)
        guard let rawString = String(bytes: data, encoding: .utf8) else {
            throw EncodingError.invalidValue("", .init(
                                                codingPath: container.codingPath,
                                                debugDescription: "RawStringJSONContainer: Impossible to convert the encoded JSONValue data to a string.")
            )
        }
        try container.encode(rawString)
    }
    
    init(wrapping: JSONValue) {
        self.wrapping = wrapping
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawJSON = try container.decode(String.self)
        guard let data = rawJSON.data(using: .utf8) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "RawStringJSONContainer: Impossible to convert the JSON string to data."
            )
        }
        self.wrapping = try RawStringJSONContainer.rawDecoder.decode(JSONValue.self, from: data)
    }
    
    let wrapping: JSONValue
}
