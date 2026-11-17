#!/bin/sh
# The checks CI runs: formatting, analysis, and every package's tests. More checks arrive with the slices that need
# them: the dependency direction of core with the first optional package, the widget checks with the kits, the
# scenario table and the web builds with the examples.
set -e
cd "$(dirname "$0")/.."
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
for package in packages/*/; do
  [ -d "$package/test" ] || continue
  echo "== $package"
  (cd "$package" && dart test)
done
