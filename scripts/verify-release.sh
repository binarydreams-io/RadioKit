#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'Usage: %s X.Y.Z\n' "$0" >&2
  exit 2
}
OUTPUT_DIR="${RADIOKIT_RELEASE_OUTPUT:-$PROJECT_DIR/release-output}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/radiokit-release.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

git -C "$PROJECT_DIR" rev-parse --verify HEAD >/dev/null || {
  printf '%s\n' "Release error: Git HEAD is required" >&2
  exit 1
}

FILE_VERSION="$(tr -d '[:space:]' < "$PROJECT_DIR/Sources/RadioKit/VERSION")"
[[ "$VERSION" == "$FILE_VERSION" ]] || {
  printf '%s\n' "Release error: VERSION does not match the requested release" >&2
  exit 1
}
HEAD_VERSION="$(git -C "$PROJECT_DIR" show HEAD:Sources/RadioKit/VERSION | tr -d '[:space:]')"
[[ "$VERSION" == "$HEAD_VERSION" ]] || {
  printf '%s\n' "Release error: VERSION in HEAD does not match" >&2
  exit 1
}

if [[ -n "${GITHUB_REF_NAME:-}" ]]; then
  [[ "$GITHUB_REF_NAME" == "$VERSION" ]] || {
    printf '%s\n' "Release error: tag does not match VERSION" >&2
    exit 1
  }
  git -C "$PROJECT_DIR" tag --points-at HEAD | grep -Fxq "$VERSION" || {
    printf '%s\n' "Release error: the release tag does not point to HEAD" >&2
    exit 1
  }
fi

git -C "$PROJECT_DIR" show HEAD:README.md | grep -Fq "Version \`$VERSION\`"
git -C "$PROJECT_DIR" show HEAD:CHANGELOG.md | grep -Eq "^## ${VERSION//./\\.} - [0-9]{4}-[0-9]{2}-[0-9]{2}$"
git -C "$PROJECT_DIR" show HEAD:CITATION.cff | grep -Eq "^version: ['\"]?${VERSION//./\\.}['\"]?$"
git -C "$PROJECT_DIR" show HEAD:Tests/RadioKitTests/RadioKitReleaseTests.swift \
  | grep -Fq "#expect(RadioKitRelease.version == \"$VERSION\")"
grep -Fq 'SWIFT_VERSION="6.3.3"' "$SCRIPT_DIR/toolchain.env"
grep -Fq 'SWIFT_TOOLS_VERSION="6.3"' "$SCRIPT_DIR/toolchain.env"
[[ "$(tr -d '[:space:]' < "$PROJECT_DIR/.swift-version")" == "6.3.3" ]]

"$SCRIPT_DIR/verify-package-shape.sh"

mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="RadioKit-$VERSION.tar.gz"
ARCHIVE="$OUTPUT_DIR/$ARCHIVE_NAME"
git -C "$PROJECT_DIR" archive \
  --format=tar.gz \
  --prefix="RadioKit-$VERSION/" \
  --output="$TEMP_DIR/$ARCHIVE_NAME" \
  HEAD
cp "$TEMP_DIR/$ARCHIVE_NAME" "$ARCHIVE"
tar -tzf "$ARCHIVE" > "$TEMP_DIR/archive-files.txt"

for path in \
  LICENSE \
  NOTICE.md \
  CREDITS.md \
  PROVENANCE.md \
  README.md \
  CHANGELOG.md \
  CITATION.cff \
  SECURITY.md \
  SUPPORT.md \
  CODE_OF_CONDUCT.md \
  CONTRIBUTING.md \
  LIMITATIONS.md \
  Documentation/architecture.md \
  Package.swift \
  Sources/RadioKit/VERSION \
  Sources/RadioKit/PrivacyInfo.xcprivacy \
  Sources/RadioKit/RadioKit.docc/RadioKit.md \
  Examples/RadioPlayer/RadioPlayer.xcodeproj/project.pbxproj \
  Examples/RadioPlayer/RadioPlayer.xcodeproj/xcshareddata/xcschemes/RadioPlayer.xcscheme; do
  grep -Fxq "RadioKit-$VERSION/$path" "$TEMP_DIR/archive-files.txt" || {
    printf 'Release error: archive missing %s\n' "$path" >&2
    exit 1
  }
done
grep -Eq "^RadioKit-${VERSION//./\\.}/Examples/RadioPlayer/RadioPlayer/.+\.swift$" \
  "$TEMP_DIR/archive-files.txt" || {
  printf '%s\n' "Release error: archive contains no RadioPlayer Swift source" >&2
  exit 1
}
grep -Eq "^RadioKit-${VERSION//./\\.}/Examples/RadioPlayer/.+/Info\.plist$" \
  "$TEMP_DIR/archive-files.txt" || {
  printf '%s\n' "Release error: archive contains no RadioPlayer Info.plist" >&2
  exit 1
}

mkdir -p "$TEMP_DIR/versioned"
tar -xzf "$ARCHIVE" -C "$TEMP_DIR/versioned"
mv "$TEMP_DIR/versioned/RadioKit-$VERSION" "$TEMP_DIR/versioned/RadioKit"
PACKAGE_DIR="$TEMP_DIR/versioned/RadioKit"
git -C "$PACKAGE_DIR" init --quiet
git -C "$PACKAGE_DIR" add .
git -C "$PACKAGE_DIR" \
  -c user.name=RadioKit \
  -c user.email=release@localhost \
  commit --quiet \
  -m "RadioKit $VERSION"
git -C "$PACKAGE_DIR" tag "$VERSION"
"$PACKAGE_DIR/scripts/verify-package-shape.sh"
RADIOKIT_PACKAGE_PATH="$PACKAGE_DIR" \
  RADIOKIT_PACKAGE_VERSION="$VERSION" \
  "$PACKAGE_DIR/scripts/verify-consumer.sh"

if command -v sha256sum >/dev/null; then
  (cd "$OUTPUT_DIR" && sha256sum "$ARCHIVE_NAME") > "$ARCHIVE.sha256"
  (cd "$OUTPUT_DIR" && sha256sum --check "$ARCHIVE_NAME.sha256")
else
  (cd "$OUTPUT_DIR" && shasum -a 256 "$ARCHIVE_NAME") > "$ARCHIVE.sha256"
  (cd "$OUTPUT_DIR" && shasum -a 256 --check "$ARCHIVE_NAME.sha256")
fi

printf 'Release archive verified at %s\n' "$ARCHIVE"
