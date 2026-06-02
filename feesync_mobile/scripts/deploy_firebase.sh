#!/bin/bash
# Firebase App Distribution Deployment Script (Bash for macOS/Linux)
# Usage: ./scripts/deploy_firebase.sh -p Android -r "New features" -g "internal-testers"

# Exit on error
set -e

PLATFORM="Android"
RELEASE_NOTES="Beta release built on $(date '+%Y-%m-%d %H:%M:%S')"
GROUPS=""

# Parse options
while getopts "p:r:g:h" opt; do
  case ${opt} in
    p ) PLATFORM=$OPTARG ;;
    r ) RELEASE_NOTES=$OPTARG ;;
    g ) GROUPS=$OPTARG ;;
    h )
      echo "Usage: $0 [options]"
      echo "  -p  Platform: Android, iOS, or Both (default: Android)"
      echo "  -r  Release notes (default: current timestamp)"
      echo "  -g  Tester groups (comma-separated)"
      exit 0
      ;;
    \? )
      echo "Invalid option. Use -h for help."
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE="$SCRIPT_DIR/../.env.firebase"

# 1. Load environment variables from .env.firebase
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.firebase file not found at: $ENV_FILE" >&2
    echo "Please copy .env.firebase.example to .env.firebase and populate it with your Firebase App IDs."
    exit 1
fi

echo "Loading environment variables from $ENV_FILE..."
# Read file and export variables, ignoring comments and empty lines
while IFS= read -r line || [ -n "$line" ]; do
    if [[ ! "$line" =~ ^# ]] && [[ "$line" =~ = ]]; then
        # Strip quotes
        var_name=$(echo "$line" | cut -d'=' -f1 | xargs)
        var_val=$(echo "$line" | cut -d'=' -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        export "$var_name"="$var_val"
    fi
done < "$ENV_FILE"

ANDROID_APP_ID=$FIREBASE_APP_ID_ANDROID
IOS_APP_ID=$FIREBASE_APP_ID_IOS
DEFAULT_GROUPS=$FIREBASE_TESTERS_GROUP

# Resolve tester groups
if [ -z "$GROUPS" ]; then
    if [ -n "$DEFAULT_GROUPS" ]; then
        GROUPS=$DEFAULT_GROUPS
    else
        GROUPS="internal-testers"
    fi
fi

# 2. Check Prerequisites
echo "Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter SDK is not installed or not in your system PATH." >&2
    exit 1
fi

if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI is not installed." >&2
    echo "Please install it using: npm install -g firebase-tools"
    exit 1
fi

cd "$SCRIPT_DIR/.."

# 3. Build & Deploy Android
if [ "$PLATFORM" = "Android" ] || [ "$PLATFORM" = "Both" ]; then
    if [ -z "$ANDROID_APP_ID" ] || [ "$ANDROID_APP_ID" = "YOUR_ANDROID_APP_ID_HERE" ]; then
        echo "Error: FIREBASE_APP_ID_ANDROID is not configured in .env.firebase." >&2
        exit 1
    fi

    echo -e "\n--- [Building Android Release APK] ---"
    flutter build apk --release

    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [ ! -f "$APK_PATH" ]; then
        echo "Error: APK build succeeded but release file was not found at $APK_PATH." >&2
        exit 1
    fi

    echo -e "\n--- [Uploading Android to Firebase App Distribution] ---"
    firebase appdistribution:distribute "$APK_PATH" \
        --app "$ANDROID_APP_ID" \
        --release-notes "$RELEASE_NOTES" \
        --groups "$GROUPS"
        
    echo -e "\nAndroid deployment complete!"
fi

# 4. Build & Deploy iOS
if [ "$PLATFORM" = "iOS" ] || [ "$PLATFORM" = "Both" ]; then
    if [ -z "$IOS_APP_ID" ] || [ "$IOS_APP_ID" = "YOUR_IOS_APP_ID_HERE" ]; then
        echo "Error: FIREBASE_APP_ID_IOS is not configured in .env.firebase." >&2
        exit 1
    fi

    echo -e "\n--- [Building iOS Release IPA] ---"
    flutter build ipa --release

    # Find the IPA file in build/ios/ipa
    IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -n 1)
    if [ -z "$IPA_PATH" ]; then
        echo "Error: IPA build succeeded but release file was not found under build/ios/ipa/" >&2
        exit 1
    fi

    echo -e "\n--- [Uploading iOS to Firebase App Distribution] ---"
    firebase appdistribution:distribute "$IPA_PATH" \
        --app "$IOS_APP_ID" \
        --release-notes "$RELEASE_NOTES" \
        --groups "$GROUPS"
        
    echo -e "\niOS deployment complete!"
fi

echo -e "\nFirebase App Distribution script finished successfully!"
