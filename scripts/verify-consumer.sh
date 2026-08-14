#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="${RADIOKIT_PACKAGE_PATH:-$PROJECT_DIR}"
PACKAGE_DIR="$(cd "$PACKAGE_DIR" && pwd)"
PACKAGE_VERSION="${RADIOKIT_PACKAGE_VERSION:-}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/radiokit-consumer.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

if [[ -n "$PACKAGE_VERSION" && ! "$PACKAGE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf '%s\n' "Consumer error: package version must use X.Y.Z SemVer" >&2
  exit 1
fi

mkdir -p "$TEMP_DIR/Consumer/Sources/RadioKitConsumer"
swift -warnings-as-errors - \
  "$TEMP_DIR/Consumer/Package.swift" "$PACKAGE_DIR" "$PACKAGE_VERSION" <<'SWIFT'
import Foundation

let outputPath = CommandLine.arguments[1]
let packagePath = CommandLine.arguments[2]
let packageVersion = CommandLine.arguments[3]
let dependency: String

if packageVersion.isEmpty {
  let escapedPath = packagePath.replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: "\"", with: "\\\"")
  dependency = #".package(path: "\#(escapedPath)")"#
} else {
  let packageURL = URL(fileURLWithPath: packagePath, isDirectory: true).absoluteString
  dependency = #".package(url: "\#(packageURL)", exact: "\#(packageVersion)")"#
}

let manifest = """
// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "RadioKitConsumer",
  platforms: [.macOS(.v14)],
  dependencies: [
    \(dependency),
  ],
  targets: [
    .executableTarget(
      name: "RadioKitConsumer",
      dependencies: [.product(name: "RadioKit", package: "RadioKit")]
    ),
  ]
)
"""

try manifest.write(toFile: outputPath, atomically: true, encoding: .utf8)
SWIFT

cp "$PACKAGE_DIR/CompileFixtures/Consumer/Sources/RadioKitConsumer/main.swift" \
  "$TEMP_DIR/Consumer/Sources/RadioKitConsumer/main.swift"

swift build \
  --package-path "$TEMP_DIR/Consumer" \
  --scratch-path "$TEMP_DIR/build" \
  -Xswiftc -warnings-as-errors
OUTPUT="$(swift run \
  --package-path "$TEMP_DIR/Consumer" \
  --scratch-path "$TEMP_DIR/build" \
  RadioKitConsumer)"

VERSION="$(tr -d '[:space:]' < "$PACKAGE_DIR/Sources/RadioKit/VERSION")"
[[ -z "$PACKAGE_VERSION" || "$PACKAGE_VERSION" == "$VERSION" ]] || {
  printf '%s\n' "Consumer error: requested version does not match VERSION" >&2
  exit 1
}
printf '%s\n' "$OUTPUT" | grep -Fq "RadioKit consumer: Fixture Radio uses 1 stream"
printf '%s\n' "$OUTPUT" | grep -Fxq "$VERSION"

printf '%s\n' "Consumer fixture passed."
