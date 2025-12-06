# Project Guidelines

## Testing

### Test Device Configuration
When running tests via `xcodebuild`, always use the following destination:
```
-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1'
```

This ensures consistency across test runs and matches the project's target iOS version.
