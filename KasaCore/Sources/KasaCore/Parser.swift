//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import Foundation

public struct Parser<Output> {
    public let run: (inout Substring) -> Output?
}

public extension Parser {
  func run(_ input: String) -> (match: Output?, rest: Substring) {
    var input = input[...]
    let match = self.run(&input)
    return (match, input)
  }
}


public extension Parser {
    func map<NewOutput>(_ f: @escaping (Output) -> NewOutput) -> Parser<NewOutput> {
      .init { input in
        self.run(&input).map(f)
      }
    }
    
    func flatMap<NewOutput>(
      _ f: @escaping (Output) -> Parser<NewOutput>
    ) -> Parser<NewOutput> {
      .init { input in
        let original = input
        let output = self.run(&input)
        let newParser = output.map(f)
        guard let newOutput = newParser?.run(&input) else {
          input = original
          return nil
        }
        return newOutput
      }
    }
}

public extension Parser {
    static func always(_ output: Output) -> Self {
      Self { _ in output }
    }

    static var never: Self {
      Self { _ in nil }
    }
}

public extension Parser where Output == Void {
  static func prefix(_ p: String) -> Self {
    Self { input in
      guard input.hasPrefix(p) else { return nil }
      input.removeFirst(p.count)
      return ()
    }
  }
}

public extension Parser where Output == Substring {
  static func prefix(while p: @escaping (Character) -> Bool) -> Self {
    Self { input in
      let output = input.prefix(while: p)
      input.removeFirst(output.count)
      return output
    }
  }

  static func prefix(upTo substring: Substring) -> Self {
    Self { input in
      guard let endIndex = input.range(of: substring)?.lowerBound
      else { return nil }

      let match = input[..<endIndex]

      input = input[endIndex...]

      return match
    }
  }

  static func prefix(through substring: Substring) -> Self {
    Self { input in
      guard let endIndex = input.range(of: substring)?.upperBound
      else { return nil }

      let match = input[..<endIndex]

      input = input[endIndex...]

      return match
    }
  }
}

extension Parser: ExpressibleByUnicodeScalarLiteral where Output == Void {
    public typealias UnicodeScalarLiteralType = StringLiteralType
}

extension Parser: ExpressibleByExtendedGraphemeClusterLiteral where Output == Void {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
}

extension Parser: ExpressibleByStringLiteral where Output == Void {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self = .prefix(value)
    }
}

public extension Parser {
  static func oneOf(_ ps: [Self]) -> Self {
    .init { input in
      for p in ps {
        if let match = p.run(&input) {
          return match
        }
      }
      return nil
    }
  }
  
  static func oneOf(_ ps: Self...) -> Self {
    self.oneOf(ps)
  }
}

public extension Parser {

    func zeroOrMore(
      separatedBy separator: Parser<Void> = ""
    ) -> Parser<[Output]> {
      Parser<[Output]> { input in
        var rest = input
        var matches: [Output] = []
        while let match = self.run(&input) {
          rest = input
          matches.append(match)
          if separator.run(&input) == nil {
            return matches
          }
        }
        input = rest
        return matches
      }
    }
    
    func oneOrMore(
        separatedBy separator: Parser<Void> = ""
    ) -> Parser<[Output]> {
        return zeroOrMore(separatedBy: separator).flatMap{ $0.isEmpty ? .never : .always($0)}
    }
}




public func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    return Parser<(A, B)> { str -> (A, B)? in
        let original = str
        guard let matchA = a.run(&str) else { return nil }
        guard let matchB = b.run(&str) else {
            str = original
            return nil
        }
        return (matchA, matchB)
    }
}


public func zip<A, B, C>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>
) -> Parser<(A, B, C)> {
    return zip(a, zip(b, c))
        .map { a, bc in (a, bc.0, bc.1) }
}

public func zip<A, B, C, D>(
    _ a: Parser<A>,
    _ b: Parser<B>,
    _ c: Parser<C>,
    _ d: Parser<D>
) -> Parser<(A, B, C, D)> {
    return zip(a, zip(b, c, d))
        .map { a, bcd in (a, bcd.0, bcd.1, bcd.2) }
}

public extension Parser where Output == Character {
    
    static let char = Self { input in
        guard !input.isEmpty else { return nil }
        return input.removeFirst()
    }
    
    static let number = char
        .flatMap { $0.isNumber ? .always($0) : .never }
    
    static let letter = char
        .flatMap { $0.isLetter ? .always($0) : .never }
}

public extension Parser {
  func skip<B>(_ p: Parser<B>) -> Self {
    zip(self, p).map { a, _ in a }
  }
}

public extension Parser {
    func take<NewOutput>(_ p: Parser<NewOutput>) -> Parser<(Output, NewOutput)> {
        zip(self, p)
    }
    
    func take<A, B, C>(_ p: Parser<C>) -> Parser<(A, B, C)> where Output == (A, B) {
        zip(self, p).map { ab, c in
            (ab.0, ab.1, c)
        }
    }
}

public extension Parser {
  static func skip(_ p: Self) -> Parser<Void> {
    p.map { _ in () }
  }
}

public extension Parser where Output == Void {
  func take<A>(_ p: Parser<A>) -> Parser<A> {
    zip(self, p).map { _, a in a }
  }
}

public extension Parser where Output == Void {
    static let end = Self { input in
        guard input.isEmpty else { return nil }
        return ()
    }
}
