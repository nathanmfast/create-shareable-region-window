#!/bin/bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <application-path> <output-zip>" >&2
  exit 2
fi

app_path=$1
output_zip=$2
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
install_file="$script_dir/../packaging/INSTALL.txt"

if [[ ! -d "$app_path" ]]; then
  echo "Application bundle not found: $app_path" >&2
  exit 1
fi

if [[ ! -f "$install_file" ]]; then
  echo "Installation guide not found: $install_file" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_zip")"
package_root=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/csrw-package.XXXXXX")
trap 'rm -rf "$package_root"' EXIT

package_dir="$package_root/Create Shareable Region Window"
mkdir -p "$package_dir"
ditto "$app_path" "$package_dir/CreateShareableRegionWindow.app"
cp "$install_file" "$package_dir/INSTALL.txt"

ditto \
  -c \
  -k \
  --sequesterRsrc \
  --keepParent \
  "$package_dir" \
  "$output_zip"
