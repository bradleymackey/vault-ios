import Foundation

/// Wrapper around the application’s Darwin notification center from CFNotificationCenter.h
///
/// - Note: On macOS, consider using DistributedNotificationCenter instead
public final class DarwinNotificationCenter {
    private init() {}

    private let center = CFNotificationCenterGetDarwinNotifyCenter()

    /// The application’s Darwin notification center.
    @MainActor
    public static let shared = DarwinNotificationCenter()

    /// Posts a Darwin notification with the specified name.
    public func post(name: DarwinNotificationName) {
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: name.rawValue as CFString),
            nil,
            nil,
            true
        )
    }

    /// Registers an observer closure for Darwin notifications of the specified name.
    ///
    /// Retain the returned `DarwinNotificationObservation` to keep the observer active.
    ///
    /// Save the returned value in a variable, or store it in a bag.
    ///
    /// ```
    /// observation.store(in: &disposeBag)
    /// ```
    ///
    /// To stop observing the notifiation, deallocate the `DarwinNotificationObservation`, or call its `cancel()`
    /// method.
    public func addObserver(
        name: DarwinNotificationName,
        callback: @escaping @Sendable () -> Void
    ) -> DarwinNotificationObservation {
        let observation = DarwinNotificationObservation(callback: callback)

        let pointer = UnsafeRawPointer(Unmanaged.passUnretained(observation.closure).toOpaque())

        CFNotificationCenterAddObserver(
            center,
            pointer,
            notificationCallback,
            name.rawValue as CFString,
            nil,
            .deliverImmediately
        )

        return observation
    }
}

public struct DarwinNotificationName: Sendable {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

private func notificationCallback(
    center _: CFNotificationCenter?,
    observation: UnsafeMutableRawPointer?,
    name _: CFNotificationName?,
    object _: UnsafeRawPointer?,
    userInfo _: CFDictionary?
) {
    guard let pointer = observation else { return }

    let closure = Unmanaged<DarwinNotificationObservation.Closure>.fromOpaque(pointer).takeUnretainedValue()

    closure.invoke()
}

/// Object that retains an observation of Darwin notifications.
///
/// Retain this object to keep the observer active.
///
/// Save this object in a variable, or store it in a bag.
///
/// ```
/// observation.store(in: &disposeBag)
/// ```
///
/// To stop observing the notifiation, deallocate the this object, or call the `cancel()` method.
public final class DarwinNotificationObservation: Cancellable, Sendable {
    // Wrapper class around the callback closure.
    // This object can stay alive in the cancel block, after this Observation has been deallocated.
    fileprivate final class Closure: Sendable {
        let invoke: @Sendable () -> Void
        init(callback: @escaping @Sendable () -> Void) {
            invoke = callback
        }
    }

    fileprivate let closure: Closure

    fileprivate init(callback: @escaping @Sendable () -> Void) {
        closure = Closure(callback: callback)
    }

    deinit {
        cancel()
    }

    /// Cancels the Darwin notification observation.
    public func cancel() {
        // Notifications are always delivered on the main thread.
        // So we also remove the observer on the main thread,
        // to make sure the closure object isn't deallocated during the execution of a notification.
        DispatchQueue.main.async { [closure] in
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            let pointer = UnsafeRawPointer(Unmanaged.passUnretained(closure).toOpaque())
            CFNotificationCenterRemoveObserver(center, pointer, nil, nil)
        }
    }
}

// MARK: - AsyncSequence

extension DarwinNotificationCenter {
    /// Returns an asynchronous sequence of notifications for a given notification name.
    func notifications(named name: DarwinNotificationName) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observation = addObserver(name: name) {
                continuation.yield()
            }
            continuation.onTermination = { _ in
                observation.cancel()
            }
        }
    }
}

// MARK: - Combine

#if canImport(Combine)

import Combine

extension DarwinNotificationCenter {
    /// Returns a publisher that emits events when broadcasting notifications.
    ///
    /// - Parameters:
    ///   - name: The name of the notification to publish.
    /// - Returns: A publisher that emits events when broadcasting notifications.
    public func publisher(for name: DarwinNotificationName) -> DarwinNotificationCenter.Publisher {
        Publisher(center: self, name: name)
    }
}

extension DarwinNotificationCenter {
    /// A publisher that emits when broadcasting notifications.
    public struct Publisher: Combine.Publisher {
        public typealias Output = Void
        public typealias Failure = Never
        public let center: DarwinNotificationCenter
        public let name: DarwinNotificationName
        public init(center: DarwinNotificationCenter, name: DarwinNotificationName) {
            self.center = center
            self.name = name
        }

        public func receive<S: Sendable>(subscriber: S) where S: Subscriber, S.Failure == Never, S.Input == Output {
            let observation = center.addObserver(name: name) {
                _ = subscriber.receive()
            }

            subscriber.receive(subscription: observation)
        }
    }
}

extension DarwinNotificationObservation: Subscription {
    public func request(_: Subscribers.Demand) {}
}

#endif
