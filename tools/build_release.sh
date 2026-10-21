#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
python3 tools/setup_android.py
if [ ! -f .toolchain/capital-test.keystore ]; then
 keytool -genkeypair -keystore .toolchain/capital-test.keystore -storepass android -alias capitaltest -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=CAPITAL Personal Test, O=CAPITAL, C=DE'
fi
godot --headless --path game --editor --quit
godot --headless --path game --script res://tests/economy_test.gd
git rev-parse HEAD > dist/SOURCE-COMMIT.txt
GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$project_root/.toolchain/capital-test.keystore" \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=capitaltest \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android \
godot --headless --path game --export-release Android ../dist/CAPITAL-v1.0.apk
.toolchain/android-sdk/build-tools/35.0.0/apksigner verify --verbose dist/CAPITAL-v1.0.apk
python3 tools/package_release.py
