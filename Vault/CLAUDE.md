# Project Guidelines

## Testing

### Test Device Configuration

**For snapshot tests**, always use the following destination:
```bash
-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'
```

**For other tests**, use:
```bash
-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1'
```

This ensures consistency across test runs. Snapshot tests specifically require OS=26.2 as documented in the project README.

### Running Snapshot Tests

Example command for running snapshot tests:
```bash
xcodebuild test -scheme VaultiOSTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -only-testing:VaultiOSTests/VaultItemFeedViewSnapshotTests
```
