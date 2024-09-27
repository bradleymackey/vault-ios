import Foundation
import FoundationExtensions
import TestHelpers
import Testing

enum TaskRaceTests {
    struct FirstResolved {
        @Test
        func noScheduledTasksThrows() async throws {
            await #expect(throws: TaskRaceError.noTasksScheduled) {
                let task = Task.race(firstResolved: [TaskRace<Void>]())
                try await task.value
            }
        }

        @Test("Cancellation is always checked before returning")
        func noScheduledTasksCancelledThrowsCancellation() async throws {
            await #expect(throws: CancellationError.self) {
                let task = Task.race(firstResolved: [TaskRace<Void>]())
                task.cancel()
                try await task.value
            }
        }

        @Test
        func propagatesCancellation() async throws {
            await #expect(throws: CancellationError.self) {
                let task = Task.race(firstResolved: [longTask()])
                task.cancel()
                _ = try await task.value
            }
        }

        @Test(arguments: [TestTask.t1, .t2, .t3])
        func firstResolvedReturnsFirstResolvedValue(resolvingTask: TestTask) async throws {
            let pending1 = PendingValue<Void>()
            let pending2 = PendingValue<Void>()
            let pending3 = PendingValue<Void>()
            let t1: TaskRace<Int> = {
                try await pending1.awaitValue()
                return TestTask.t1.testValue
            }
            let t2: TaskRace<Int> = {
                try await pending2.awaitValue()
                return TestTask.t2.testValue
            }
            let t3: TaskRace<Int> = {
                try await pending3.awaitValue()
                return TestTask.t3.testValue
            }
            let task = Task.race(firstResolved: [t1, t2, t3])
            switch resolvingTask {
            case .t1: await pending1.fulfill()
            case .t2: await pending2.fulfill()
            case .t3: await pending3.fulfill()
            }
            let value = try await task.value

            #expect(value == resolvingTask.testValue)
        }

        @Test(arguments: [TestTask.t1, .t2, .t3])
        func errorInAnyTaskPropagatesError(erroringTask: TestTask) async throws {
            let pending1 = PendingValue<Void>()
            let pending2 = PendingValue<Void>()
            let pending3 = PendingValue<Void>()
            let t1: TaskRace<Void> = {
                try await pending1.awaitValue()
                if erroringTask == .t1 {
                    throw SomeError()
                }
            }
            let t2: TaskRace<Void> = {
                try await pending2.awaitValue()
                if erroringTask == .t2 {
                    throw SomeError()
                }
            }
            let t3: TaskRace<Void> = {
                try await pending3.awaitValue()
                if erroringTask == .t3 {
                    throw SomeError()
                }
            }
            let task = Task.race(firstResolved: [t1, t2, t3])
            switch erroringTask {
            case .t1: await pending1.fulfill()
            case .t2: await pending2.fulfill()
            case .t3: await pending3.fulfill()
            }
            await #expect(throws: SomeError.self, performing: {
                _ = try await task.value
            })
        }
    }

    struct FirstValue {
        @Test
        func noScheduledTasksThrows() async throws {
            await #expect(throws: TaskRaceError.noTasksScheduled) {
                let task = Task.race(firstValue: [TaskRace<Void>]())
                try await task.value
            }
        }

        @Test("Cancellation is always checked before returning")
        func noScheduledTasksCancelledThrowsCancellation() async throws {
            await #expect(throws: CancellationError.self) {
                let task = Task.race(firstValue: [TaskRace<Void>]())
                task.cancel()
                try await task.value
            }
        }

        @Test
        func propagatesCancellation() async throws {
            await #expect(throws: CancellationError.self) {
                let task = Task.race(firstValue: [longTask()])
                task.cancel()
                _ = try await task.value
            }
        }

        @Test(arguments: [TestTask.t1, .t2, .t3])
        func firstResolvedReturnsFirstResolvedValue(resolvingTask: TestTask) async throws {
            let pending1 = PendingValue<Void>()
            let pending2 = PendingValue<Void>()
            let pending3 = PendingValue<Void>()
            let t1: TaskRace<Int> = {
                try await pending1.awaitValue()
                return TestTask.t1.testValue
            }
            let t2: TaskRace<Int> = {
                try await pending2.awaitValue()
                return TestTask.t2.testValue
            }
            let t3: TaskRace<Int> = {
                try await pending3.awaitValue()
                return TestTask.t3.testValue
            }
            let task = Task.race(firstValue: [t1, t2, t3])
            switch resolvingTask {
            case .t1: await pending1.fulfill()
            case .t2: await pending2.fulfill()
            case .t3: await pending3.fulfill()
            }
            let value = try await task.value

            #expect(value == resolvingTask.testValue)
        }

        @Test
        func ignoresErrorsUntilValue() async throws {
            let pending1 = PendingValue<Void>()
            let pending2 = PendingValue<Void>()
            let pending3 = PendingValue<Void>()
            let t1: TaskRace<Int> = {
                try await pending1.awaitValue()
                throw SomeError()
            }
            let t2: TaskRace<Int> = {
                try await pending2.awaitValue()
                throw SomeError()
            }
            let t3: TaskRace<Int> = {
                try await pending3.awaitValue()
                return 103
            }
            let task = Task.race(firstValue: [t1, t2, t3])
            await pending1.fulfill()
            await pending2.fulfill()
            await pending3.fulfill()
            let value = try await task.value

            #expect(value == 103)
        }

        @Test
        func allErroringTasksReturnsNil() async throws {
            let pending1 = PendingValue<Void>()
            let pending2 = PendingValue<Void>()
            let pending3 = PendingValue<Void>()
            let t1: TaskRace<Int> = {
                try await pending1.awaitValue()
                throw SomeError()
            }
            let t2: TaskRace<Int> = {
                try await pending2.awaitValue()
                throw SomeError()
            }
            let t3: TaskRace<Int> = {
                try await pending3.awaitValue()
                throw SomeError()
            }
            let task = Task.race(firstValue: [t1, t2, t3])
            await pending1.fulfill()
            await pending2.fulfill()
            await pending3.fulfill()
            let value = try await task.value

            #expect(value == nil)
        }
    }
}

private func longTask() -> TaskRace<Void> {
    {
        try await suspendForever()
    }
}

private struct SomeError: Error {}

enum TestTask: Equatable {
    case t1, t2, t3

    var testValue: Int {
        switch self {
        case .t1: 101
        case .t2: 102
        case .t3: 103
        }
    }
}
