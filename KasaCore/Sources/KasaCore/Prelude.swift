//
//  Prelude.swift
//  Prelude
//
//  Created by Simon-Pierre Roy on 9/24/19.
//

import Combine
import Foundation

/// Applies a value transformation to an immutable setter function.
///
/// - Parameters:
///   - setter: An immutable setter function.
///   - f: A value transform function.
/// - Returns: A root transform function.
public func over<S, T, A, B>(
    _ setter: (@escaping (A) -> B) -> (S) -> T,
    _ f: @escaping (A) -> B
)
    -> (S) -> T
{

    return setter(f)
}

/// Applies a value to an immutable setter function.
///
/// - Parameters:
///   - setter: An immutable setter function.
///   - value: A new value.
/// - Returns: A root transform function.
public func set<S, T, A, B>(
    _ setter: (@escaping (A) -> B) -> (S) -> T,
    _ value: B
)
    -> (S) -> T
{

    return over(setter) { _ in value }
}

// MARK: - Mutation
/// Applies a mutable value transformation to a mutable setter function.
///
/// - Parameters:
///   - setter: A mutable setter function.
///   - f: A mutable value transform function.
/// - Returns: A mutable root transform function.
public func mver<S, A>(
    _ setter: (@escaping (inout A) -> Void) -> (inout S) -> Void,
    _ f: @escaping (inout A) -> Void
)
    -> (inout S) -> Void
{

    return setter(f)
}

/// Applies a mutable value transformation to a reference-mutable setter function.
///
/// - Parameters:
///   - setter: A reference-mutable setter function.
///   - f: A mutable value transform function.
/// - Returns: A reference-mutable root transform function.
public func mver<S, A>(
    _ setter: (@escaping (inout A) -> Void) -> (S) -> Void,
    _ f: @escaping (inout A) -> Void
)
    -> (S) -> Void
where S: AnyObject {

    return setter(f)
}

/// Applies a reference-mutable value transformation to a reference-mutable setter function.
///
/// - Parameters:
///   - setter: A reference-mutable setter function.
///   - f: A mutable value transform function.
/// - Returns: A reference-mutable root transform function.
public func mver<S, A>(
    _ setter: (@escaping (A) -> Void) -> (S) -> Void,
    _ f: @escaping (A) -> Void
)
    -> (S) -> Void
where S: AnyObject, A: AnyObject {

    return setter(f)
}

/// Applies a value to a mutable setter function.
///
/// - Parameters:
///   - setter: An mutable setter function.
///   - value: A new value.
/// - Returns: A mutable root transform function.
public func mut<S, A>(
    _ setter: (@escaping (inout A) -> Void) -> (inout S) -> Void,
    _ value: A
)
    -> (inout S) -> Void
{

    return mver(setter) { $0 = value }
}

/// Applies a value to a reference-mutable setter function.
///
/// - Parameters:
///   - setter: An mutable setter function.
///   - value: A new value.
/// - Returns: A reference-mutable root transform function.
public func mut<S, A>(
    _ setter: (@escaping (inout A) -> Void) -> (S) -> Void,
    _ value: A
)
    -> (S) -> Void
where S: AnyObject {

    return mver(setter) { $0 = value }
}

/// Produces a getter function for a given key path. Useful for composing property access with functions.
///
///     get(\String.count)
///     // (String) -> Int
///
/// - Parameter keyPath: A key path.
/// - Returns: A getter function.
public func get<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
    return { root in root[keyPath: keyPath] }
}

/// Produces an immutable setter function for a given key path. Useful for composing property changes.
///
/// - Parameter keyPath: A key path.
/// - Returns: A setter function.
public func prop<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>
)
    -> (@escaping (Value) -> Value)
    -> (Root) -> Root
{

    return { update in
        { root in
            var copy = root
            copy[keyPath: keyPath] = update(copy[keyPath: keyPath])
            return copy
        }
    }
}

precedencegroup ForwardApplication {
    associativity: left
}

infix operator |> : ForwardApplication

precedencegroup ForwardComposition {
    associativity: left
    higherThan: ForwardApplication
}

infix operator >>> : ForwardComposition

precedencegroup SingleTypeComposition {
    associativity: left
    higherThan: ForwardApplication
}

infix operator <> : SingleTypeComposition

public func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> ((A) -> C) {
    return { a in
        g(f(a))
    }
}

public func <> <A>(f: @escaping (A) -> A, g: @escaping (A) -> A) -> ((A) -> A) {
    return f >>> g
}

public func <> <A>(f: @escaping (inout A) -> Void, g: @escaping (inout A) -> Void) -> ((inout A) -> Void) {
    return { a in
        f(&a)
        g(&a)
    }
}

public func <> <A: AnyObject>(f: @escaping (A) -> Void, g: @escaping (A) -> Void) -> (A) -> Void {
    return { a in
        f(a)
        g(a)
    }
}

public func |> <A, B>(a: A, f: (A) -> B) -> B {
    return f(a)
}

public func |> <A>(_ a: A, _ f: (inout A) -> Void) -> A {
    var a = a
    f(&a)
    return a
}

public func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

public func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
    return { b in { a in f(a)(b) } }
}

public func flip<A, C>(_ f: @escaping (A) -> () -> C) -> () -> (A) -> C {
    return { { a in f(a)() } }
}

public func zurry<A>(_ f: () -> A) -> A {
    return f()
}

prefix operator ^

public prefix func ^ <Root, Value>(kp: KeyPath<Root, Value>) -> (Root) -> Value {
    return get(kp)
}

public prefix func ^ <Root, Value>(
    kp: WritableKeyPath<Root, Value>
)
    -> (@escaping (Value) -> Value)
    -> (Root) -> Root
{

    return prop(kp)
}
public prefix func ^ <Root, Value>(
    _ kp: WritableKeyPath<Root, Value>
)
    -> (@escaping (inout Value) -> Void)
    -> (inout Root) -> Void
{

    return { update in
        { root in
            update(&root[keyPath: kp])
        }
    }
}

public func absurd<A>(_: Never) -> A {}
public func always<A>(_: A) {}
