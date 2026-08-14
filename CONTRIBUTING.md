# Contributing

RadioKit requires Swift 6.3.3 and an Apple development environment for its platform frameworks.

## Development

1. Create a focused change in the applicable `Sources/RadioKit` subsystem.
2. Add or update tests in `Tests/RadioKitTests` when behavior changes.
3. Build with warnings as errors.
4. Run focused tests, then run the complete package test suite.
5. Build DocC when public API or documentation changes.

```bash
swift build -Xswiftc -warnings-as-errors
swift test
xcodebuild docbuild -scheme RadioKit -destination 'generic/platform=macOS'
```

Do not add a live endpoint to a deterministic test.
Use controlled test URLs and test doubles for network-dependent behavior.

Do not commit credentials, private repository details, or licensed media.
Record the source and rights for any third-party material before adding it.

Use conventional commit messages.
Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
Report vulnerabilities through [SECURITY.md](SECURITY.md), not through a public issue.
