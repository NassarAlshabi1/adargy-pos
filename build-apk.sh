#!/bin/bash
# Build release APK locally using keystore

export ANDROID_KEYSTORE_PATH="$(cd "$(dirname "$0")" && pwd)/keystore.b64"
export ANDROID_KEYSTORE_PASSWORD=adargy123
export ANDROID_KEY_ALIAS=adargy-key
export ANDROID_KEY_PASSWORD=adargy123

# Convert keystore.b64 to .jks for local build
if [ -f "$(dirname "$0")/keystore.b64" ]; then
    base64 -di "$(dirname "$0")/keystore.b64" > "$(dirname "$0")/android/app/release-keystore.jks"
    export ANDROID_KEYSTORE_PATH="$(cd "$(dirname "$0")" && pwd)/android/app/release-keystore.jks"
fi

cd "$(dirname "$0")"
flutter pub get
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "Build successful! APK: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "Build failed!"
    exit 1
fi
