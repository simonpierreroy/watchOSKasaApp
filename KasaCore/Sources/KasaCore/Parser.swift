//
//  File.swift
//  
//
//  Created by Simon-Pierre Roy on 10/5/20.
//

import Foundation

public struct Parser<A> {
    public let run: (inout Substring) -> A?
}

public extension Parser {
    func run(_ str: String) -> (match: A?, rest: Substring) {
        var str = str[...]
        let match = self.run(&str)
        return (match, str)
    }
}


public extension Parser {
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        return Parser<B> { str -> B? in
            self.run(&str).map(f)
        }
    }
    
    func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        return Parser<B> { str -> B? in
            let original = str
            let matchA = self.run(&str)
            let parserB = matchA.map(f)
            guard let matchB = parserB?.run(&str) else {
                str = original
                return nil
            }
            return matchB
        }
    }
}

public extension Parser {
    static func always<A>(_ a: A) -> Parser<A> {
        return Parser<A> { _ in a }
    }
    
    static var never: Parser {
        return Parser { _ in nil }
    }
}

public extension Parser {
    static func oneOf<A>(
        _ ps: [Parser<A>]
    ) -> Parser<A> {
        return Parser<A> { str -> A? in
            for p in ps {
                if let match = p.run(&str) {
                    return match
                }
            }
            return nil
        }
    }
    
    static func zeroOrMore<A>(
        _ p: Parser<A>,
        separatedBy s: Parser<Void>
    ) -> Parser<[A]> {
        return Parser<[A]> { str in
            var rest = str
            var matches: [A] = []
            while let match = p.run(&str) {
                rest = str
                matches.append(match)
                if s.run(&str) == nil {
                    return matches
                }
            }
            str = rest
            return matches
        }
    }
    
    static func oneOrMore<A>(
        _ p: Parser<A>,
        separatedBy s: Parser<Void>
    ) -> Parser<[A]> {
        return zeroOrMore(p, separatedBy: s).flatMap{ $0.isEmpty ? .never : .always($0)}
    }
}

public extension Parser {
    static func prefix(while p: @escaping (Character) -> Bool) -> Parser<Substring> {
        return Parser<Substring> { str in
            let prefix = str.prefix(while: p)
            str.removeFirst(prefix.count)
            return prefix
        }
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


public extension Parser where A == Character {
    static let char = Parser<Character> { str in
        guard !str.isEmpty else { return nil }
        return str.removeFirst()
    }
    
    static let number = char
        .flatMap { $0.isNumber ? .always($0) : .never }
    
    static let letter = char
        .flatMap { $0.isLetter ? .always($0) : .never }
}




public extension Parser where A == Void {
    static func prefix(_ p: String) -> Parser<Void> {
        return Parser<Void> { str in
            guard str.hasPrefix(p) else { return nil }
            str.removeFirst(p.count)
            return ()
        }
    }
}
