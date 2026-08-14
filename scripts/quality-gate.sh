#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/toolchain.env"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/radiokit-quality.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

[[ "$SWIFT_VERSION" == "6.3.3" ]]
[[ "$SWIFT_TOOLS_VERSION" == "6.3" ]]
[[ "$SWIFTFORMAT_VERSION" == "0.62.1" ]]
[[ "$SWIFTLINT_VERSION" == "0.65.0" ]]
[[ "$ACTIONLINT_VERSION" == "1.7.12" ]]
[[ "$SWIFTFORMAT_MACOS_SHA256" == "7cb1cb1fae04932047c7015441c543848e8e60e1572d808d080e0a1f1661114a" ]]
[[ "$SWIFTLINT_MACOS_SHA256" == "d6cb0aa7a2f5f1ef306fc9e37bcb54dc9a26facc8f7784ac0c3dd3eccf5c6ba6" ]]
[[ "$ACTIONLINT_MACOS_X64_SHA256" == "5b44c3bc2255115c9b69e30efc0fecdf498fdb63c5d58e17084fd5f16324c644" ]]
[[ "$ACTIONLINT_MACOS_ARM64_SHA256" == "aba9ced2dee8d27fecca3dc7feb1a7f9a52caefa1eb46f3271ea66b6e0e6953f" ]]

ACTUAL_SWIFT="$(swift --version | sed -n '1s/.*version \([0-9][0-9.]*\).*/\1/p')"
[[ "$ACTUAL_SWIFT" == "$SWIFT_VERSION" ]] || {
  printf 'Quality error: expected Swift %s, found %s\n' "$SWIFT_VERSION" "$ACTUAL_SWIFT" >&2
  exit 1
}
[[ "$(tr -d '[:space:]' < "$PROJECT_DIR/.swift-version")" == "$SWIFT_VERSION" ]] || {
  printf '%s\n' "Quality error: .swift-version does not match the toolchain" >&2
  exit 1
}

for script in \
  toolchain.env \
  verify-package-shape.sh \
  verify-consumer.sh \
  generate-documentation.sh \
  quality-gate.sh \
  verify-release.sh; do
  [[ -x "$SCRIPT_DIR/$script" ]] || {
    printf 'Quality error: scripts/%s is not executable\n' "$script" >&2
    exit 1
  }
done

"$SCRIPT_DIR/verify-package-shape.sh"

if git -C "$PROJECT_DIR" ls-files | grep -E '(^|/)\.DS_Store$'; then
  printf '%s\n' "Quality error: tracked .DS_Store found" >&2
  exit 1
fi

PLACEHOLDER_PATTERN='TO''DO|FIX''ME|T''BD|<repository''-url>|YOUR[_-](REPOSITORY|TOKEN|API[_-]KEY)|github\.com/(owner|OWNER)/'
if git -C "$PROJECT_DIR" grep -I -n -E "$PLACEHOLDER_PATTERN" -- . \
  || git -C "$PROJECT_DIR" grep --untracked -I -n -E "$PLACEHOLDER_PATTERN" -- .; then
  printf '%s\n' "Quality error: repository placeholder found" >&2
  exit 1
fi

SECRET_PATTERN='AK''IA[0-9A-Z]{16}|AS''IA[0-9A-Z]{16}|AI''za[0-9A-Za-z_-]{35}|gh[pousr]''_[A-Za-z0-9_]{20,}|github_pat''_[A-Za-z0-9_]{20,}|npm''_[A-Za-z0-9]{36}|pypi-AgEIcHlwaS5vcmc''[A-Za-z0-9_-]{20,}|sk_(live|test)''_[A-Za-z0-9]{16,}|sk-proj''-[A-Za-z0-9_-]{20,}|sk-ant-api03''-[A-Za-z0-9_-]{20,}|xox[baprs]''-[A-Za-z0-9-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
if git -C "$PROJECT_DIR" grep -I -n -E "$SECRET_PATTERN" -- . \
  || git -C "$PROJECT_DIR" grep --untracked -I -n -E "$SECRET_PATTERN" -- .; then
  printf '%s\n' "Quality error: repository credential pattern found" >&2
  exit 1
fi

command -v swiftformat >/dev/null || {
  printf '%s\n' "Quality error: swiftformat is not installed" >&2
  exit 1
}
command -v swiftlint >/dev/null || {
  printf '%s\n' "Quality error: swiftlint is not installed" >&2
  exit 1
}
[[ "$(swiftformat --version)" == "$SWIFTFORMAT_VERSION" ]] || {
  printf '%s\n' "Quality error: SwiftFormat version mismatch" >&2
  exit 1
}
[[ "$(swiftlint version)" == "$SWIFTLINT_VERSION" ]] || {
  printf '%s\n' "Quality error: SwiftLint version mismatch" >&2
  exit 1
}
swiftformat \
  "$PROJECT_DIR/Package.swift" \
  "$PROJECT_DIR/Sources" \
  "$PROJECT_DIR/Tests" \
  "$PROJECT_DIR/CompileFixtures" \
  "$PROJECT_DIR/Examples/RadioPlayer/RadioPlayer" \
  --lint
swiftlint lint --strict --no-cache --config "$PROJECT_DIR/.swiftlint.yml"

shopt -s nullglob
WORKFLOW_FILES=(
  "$PROJECT_DIR"/.github/workflows/*.yml
  "$PROJECT_DIR"/.github/workflows/*.yaml
)
if (( ${#WORKFLOW_FILES[@]} > 0 )); then
  command -v actionlint >/dev/null || {
    printf '%s\n' "Quality error: actionlint is not installed" >&2
    exit 1
  }
  [[ "$(actionlint -version 2>&1 | sed -n '1p')" == "$ACTIONLINT_VERSION" ]] || {
    printf '%s\n' "Quality error: actionlint version mismatch" >&2
    exit 1
  }
  actionlint "${WORKFLOW_FILES[@]}"
fi

swift build \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$TEMP_DIR/debug" \
  -Xswiftc -warnings-as-errors
swift build \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$TEMP_DIR/release" \
  -c release \
  -Xswiftc -warnings-as-errors
swift test \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$TEMP_DIR/tests" \
  -Xswiftc -warnings-as-errors

(cd "$PROJECT_DIR" && xcodebuild \
  -scheme RadioKit \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$TEMP_DIR/ios-derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  build)
xcodebuild \
  -project "$PROJECT_DIR/Examples/RadioPlayer/RadioPlayer.xcodeproj" \
  -scheme RadioPlayer \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$TEMP_DIR/demo-derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

"$SCRIPT_DIR/generate-documentation.sh" "$TEMP_DIR/documentation"
"$SCRIPT_DIR/verify-consumer.sh"

printf '%s\n' "Quality gate passed."
