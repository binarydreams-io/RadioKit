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

# CI must use the pinned tools. A local run only warns about a different version.
check_tool_version() {
  local tool="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] && return 0
  if [[ -n "${CI:-}" ]]; then
    printf 'Quality error: expected %s %s, found %s\n' "$tool" "$expected" "$actual" >&2
    exit 1
  fi
  printf 'Quality warning: expected %s %s, found %s\n' "$tool" "$expected" "$actual" >&2
}

ACTUAL_SWIFT="$(swift --version | sed -n '1s/.*version \([0-9][0-9.]*\).*/\1/p')"
check_tool_version Swift "$SWIFT_VERSION" "$ACTUAL_SWIFT"
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
check_tool_version SwiftFormat "$SWIFTFORMAT_VERSION" "$(swiftformat --version)"
check_tool_version SwiftLint "$SWIFTLINT_VERSION" "$(swiftlint version)"
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
  check_tool_version actionlint "$ACTIONLINT_VERSION" "$(actionlint -version 2>&1 | sed -n '1p')"
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
