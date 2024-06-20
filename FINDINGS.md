# Development findings

This app has given me an amazing opportunity to really dive head-first into more of the modern technologies available on Apple platforms.
I've taken the approach of aggressive adoption so I can get a feel for these tools and figure out what limitations or issues they might have.
These are largely for the iOS 17+ APIs, for most of the Swift-first frameworks.

## 1. Be careful with `@Bindable`

In certain configurations, using nested bindable might be a mistake that causes views to incorrectly rerender.

- Never trust the simulator, always test on a real device, and do so regularly.
- Always start with @State. If you need to use `@Binding`, document why with a descriptive comment.

## 2. `#Predicate` is a little broken

`#Predicate` is a new, type-safe API in Foundation that makes predicates type-safe and easy to read.
Unfortunately there's a few limitations.

- They only support a single expression so, unless your predicate is really simple, you're likely going to have a pretty long and hard to read predicate.
- `#Predicate` doesn't like optional chaining, use `flatMap` instead. Optional chaining in a predicate may compile (if it doesn't timeout), but might lead to runtime SQL errors when used with CoreData. Neat!
- Anything other than raw & basic data types (think `Int`, `String` etc.) will likely not work in a predicate. For example, if my `@Model` has a strongly-typed, `Codable` enum vaule, then I try to query based on this enum value directly (or even trying to use `rawValue`) will likely result in a runtime error. Need to use basic types at the moment for querying. This means not inlining lots of stuff and keeping relationships between distinct models, each containing their own very basic types. Creating custom encoders/decoders for these types is a good way to ensure they are turned back into strongly-typed values.
- Creating a big chain of conditionals will likely require use of the iOS 17.4 API `Predicate<T>.evaluate`, so each predicate can be created independently then nested. Trying to nest all the logic in a single predicate means Swift can't type check it in time and will break!
