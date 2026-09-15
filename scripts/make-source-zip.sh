#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?version e.g. v2026.9.15}"
OUT="LocusCal-${VERSION}-source.zip"
rm -f "$OUT"
# Exclude git, secrets, internal-only paths
zip -r "$OUT" . \
  -x './.git/*' \
  -x './.github/*' \
  -x './LocusCal.xcodeproj/*' \
  -x './.build/*' \
  -x './DerivedData/*' \
  -x '*.xcuserstate' \
  -x './.DS_Store'
echo "Wrote $OUT"
