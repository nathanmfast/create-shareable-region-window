#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <application-path>" >&2
  exit 2
fi

app_path=$1

if [[ ! -d "$app_path" ]]; then
  echo "Application bundle not found: $app_path" >&2
  exit 1
fi

# A free ad-hoc signature does not establish a trusted Apple Developer ID, but
# it gives this exact build a code identity that macOS TCC can recognize after
# the app quits and relaunches. A different build has a different identity and
# may require Screen Recording permission again.
codesign \
  --force \
  --sign - \
  --options runtime \
  --identifier com.nathanfast.CreateShareableRegionWindow \
  --timestamp=none \
  "$app_path"

codesign --verify --strict --verbose=2 "$app_path"
