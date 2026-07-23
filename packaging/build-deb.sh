#!/usr/bin/env bash
# Builds an installable Debian package from the Flutter Linux release bundle.
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir=${OUTPUT_DIR:-"$project_dir/dist"}
staging_dir=$(mktemp -d)
cleanup() { rm -rf "$staging_dir"; }
trap cleanup EXIT

package_name=bangla-keyboard
app_dir="$staging_dir/opt/$package_name"
deb_dir="$staging_dir/DEBIAN"
control_template="$project_dir/packaging/debian/control"
pubspec="$project_dir/pubspec.yaml"

version=$(sed -n 's/^version: \([^+ ]*\)+\([0-9][0-9]*\).*/\1-\2/p' "$pubspec" | head -n 1)
version=${version:-1.0.0-1}
architecture=$(dpkg --print-architecture)

if ! command -v clang++ >/dev/null 2>&1 && ! command -v g++ >/dev/null 2>&1; then
  echo "A C++ compiler is required. Install clang or g++ before building." >&2
  exit 1
fi

if ! pkg-config --exists ibus-1.0; then
  echo "IBus development files are required. Install libibus-1.0-dev before building." >&2
  exit 1
fi

rm -rf "$project_dir/build/linux"
flutter build linux --release

bundle_dir="$project_dir/build/linux/x64/release/bundle"
if [ ! -x "$bundle_dir/$package_name" ]; then
  echo "Expected release executable was not produced: $bundle_dir/$package_name" >&2
  exit 1
fi

mkdir -p "$app_dir" "$deb_dir" "$staging_dir/usr/bin" \
  "$staging_dir/usr/share/applications" "$staging_dir/usr/share/ibus/component" \
  "$staging_dir/usr/share/icons/hicolor/512x512/apps"
cp -a "$bundle_dir/." "$app_dir/"
install -m 0755 "$project_dir/packaging/debian/bangla-keyboard" "$staging_dir/usr/bin/$package_name"
install -m 0644 "$project_dir/packaging/debian/bangla-keyboard.desktop" \
  "$staging_dir/usr/share/applications/$package_name.desktop"
install -m 0644 "$project_dir/web/icons/Icon-512.png" \
  "$staging_dir/usr/share/icons/hicolor/512x512/apps/$package_name.png"
install -m 0644 "$project_dir/packaging/ibus/bangla-avro.xml" \
  "$staging_dir/usr/share/ibus/component/bangla-avro.xml"

sed -e "s/^Version:.*/Version: $version/" -e "s/^Architecture:.*/Architecture: $architecture/" \
  "$control_template" > "$deb_dir/control"

mkdir -p "$output_dir"
package_path="$output_dir/${package_name}_${version}_${architecture}.deb"
dpkg-deb --root-owner-group --build "$staging_dir" "$package_path"
dpkg-deb --info "$package_path"
echo "Created $package_path"
