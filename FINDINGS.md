# SwiftUI findings

These are largely for the iOS 17+ API, especially using the new `@Observable` macro.

## 1. Be careful with `@Bindable`

In certain configurations, using nested bindable might be a mistake that causes views to incorrectly rerender.

### Learnings

- Never trust the simulator, always test on a real device, and do so regularly.
- Always start with @State. If you need to use `@Binding`, document why with a descriptive comment.
