#!/usr/bin/env bash
# Local CI check: format-verify, analyze, and test. Run before committing.
#
# On this Windows dev machine the tool-shells don't inherit the persisted PATH,
# so prepend the toolchain (see CLAUDE.md).
set -euo pipefail

export PATH="$PATH:/c/src/flutter/bin:/c/Android/Sdk/platform-tools"

echo "==> flutter pub get"
flutter pub get

echo "==> dart run build_runner build (codegen)"
dart run build_runner build --delete-conflicting-outputs

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "All checks passed."
