#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/radiokit-shape.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

swift package --package-path "$PROJECT_DIR" dump-package > "$TEMP_DIR/package.json"
swift package --package-path "$PROJECT_DIR" describe --type json > "$TEMP_DIR/description.json"

swift -warnings-as-errors - "$TEMP_DIR/package.json" "$TEMP_DIR/description.json" <<'SWIFT'
import Foundation

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("Package shape error: \(message)\n".utf8))
  exit(1)
}

func object(at path: String) -> [String: Any] {
  guard
    let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
    let value = try? JSONSerialization.jsonObject(with: data),
    let object = value as? [String: Any]
  else {
    fail("cannot parse \(path)")
  }
  return object
}

let package = object(at: CommandLine.arguments[1])
let description = object(at: CommandLine.arguments[2])

guard package["name"] as? String == "RadioKit" else {
  fail("package name must be RadioKit")
}
guard ((package["toolsVersion"] as? [String: Any])?["_version"] as? String) == "6.3.0" else {
  fail("tools version must be 6.3")
}

let platforms = package["platforms"] as? [[String: Any]] ?? []
guard
  platforms.count == 2,
  platforms.contains(where: {
    $0["platformName"] as? String == "ios" && $0["version"] as? String == "17.0"
  }),
  platforms.contains(where: {
    $0["platformName"] as? String == "macos" && $0["version"] as? String == "14.0"
  })
else {
  fail("platforms must be iOS 17.0 and macOS 14.0")
}

let products = package["products"] as? [[String: Any]] ?? []
guard
  products.count == 1,
  products[0]["name"] as? String == "RadioKit",
  products[0]["targets"] as? [String] == ["RadioKit"],
  ((products[0]["type"] as? [String: Any])?["library"] as? [String]) == ["automatic"]
else {
  fail("one RadioKit library product is required")
}

let targets = package["targets"] as? [[String: Any]] ?? []
guard targets.count == 2 else {
  fail("one regular target and one test target are required")
}
guard let library = targets.first(where: {
  $0["name"] as? String == "RadioKit" && $0["type"] as? String == "regular"
}) else {
  fail("RadioKit regular target is missing")
}
guard let tests = targets.first(where: {
  $0["name"] as? String == "RadioKitTests" && $0["type"] as? String == "test"
}) else {
  fail("RadioKitTests target is missing")
}
guard (library["dependencies"] as? [[String: Any]] ?? []).isEmpty else {
  fail("RadioKit target must not declare dependencies")
}
let testDependencies = tests["dependencies"] as? [[String: Any]] ?? []
guard
  testDependencies.count == 1,
  ((testDependencies[0]["byName"] as? [Any])?.first as? String) == "RadioKit"
else {
  fail("RadioKitTests must depend only on RadioKit")
}

let dependencies = package["dependencies"] as? [[String: Any]] ?? []
guard dependencies.isEmpty else {
  fail("the package must not declare direct dependencies")
}

let resources = library["resources"] as? [[String: Any]] ?? []
guard resources.count == 2 else {
  fail("RadioKit must declare PrivacyInfo.xcprivacy and VERSION resources")
}
guard resources.contains(where: {
  $0["path"] as? String == "PrivacyInfo.xcprivacy"
    && (($0["rule"] as? [String: Any])?["process"] != nil)
}) else {
  fail("PrivacyInfo.xcprivacy must be a processed resource")
}
guard resources.contains(where: {
  $0["path"] as? String == "VERSION"
    && (($0["rule"] as? [String: Any])?["copy"] != nil)
}) else {
  fail("VERSION must be a copied resource")
}

let describedTargets = description["targets"] as? [[String: Any]] ?? []
guard describedTargets.count == 2 else {
  fail("described target count does not match")
}
guard describedTargets.contains(where: {
  $0["name"] as? String == "RadioKit"
    && $0["path"] as? String == "Sources/RadioKit"
    && $0["type"] as? String == "library"
}) else {
  fail("RadioKit source path is invalid")
}
guard describedTargets.contains(where: {
  $0["name"] as? String == "RadioKitTests"
    && $0["path"] as? String == "Tests/RadioKitTests"
    && $0["type"] as? String == "test"
}) else {
  fail("RadioKitTests source path is invalid")
}
SWIFT

[[ -f "$PROJECT_DIR/Sources/RadioKit/PrivacyInfo.xcprivacy" ]] || {
  printf '%s\n' "Package shape error: PrivacyInfo.xcprivacy is missing" >&2
  exit 1
}
[[ -f "$PROJECT_DIR/Sources/RadioKit/VERSION" ]] || {
  printf '%s\n' "Package shape error: VERSION is missing" >&2
  exit 1
}
[[ -f "$PROJECT_DIR/Examples/RadioPlayer/RadioPlayer.xcodeproj/project.pbxproj" ]] || {
  printf '%s\n' "Package shape error: RadioPlayer Xcode project is missing" >&2
  exit 1
}
[[ -f "$PROJECT_DIR/Examples/RadioPlayer/RadioPlayer.xcodeproj/xcshareddata/xcschemes/RadioPlayer.xcscheme" ]] || {
  printf '%s\n' "Package shape error: RadioPlayer shared scheme is missing" >&2
  exit 1
}

printf '%s\n' "Package shape verified."
