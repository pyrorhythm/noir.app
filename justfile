default:
    just --list

build:
    xcodebuild -project noir.xcodeproj -scheme noir -configuration Debug -destination 'platform=macOS' build

test:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"

    DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-{{justfile_directory()}}/build/XcodeDerivedData}"
    RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-{{justfile_directory()}}/build/TestResults/noir.xcresult}"
    DESTINATION="${DESTINATION:-platform=macOS}"

    rm -rf "$RESULT_BUNDLE_PATH"
    mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"

    xcodebuild \
      -project noir.xcodeproj \
      -scheme noir \
      -configuration Debug \
      -destination "$DESTINATION" \
      -derivedDataPath "$DERIVED_DATA_PATH" \
      -resultBundlePath "$RESULT_BUNDLE_PATH" \
      test

ci:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"

    xcodebuild -list -project noir.xcodeproj
    just test

package:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"

    DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-{{justfile_directory()}}/build/ReleaseDerivedData}"
    ARTIFACT_DIR="${ARTIFACT_DIR:-{{justfile_directory()}}/build/Artifacts}"
    ZIP_PATH="$ARTIFACT_DIR/noir-macos.zip"

    rm -rf "$DERIVED_DATA_PATH" "$ARTIFACT_DIR"
    mkdir -p "$ARTIFACT_DIR"

    xcodebuild \
      -project noir.xcodeproj \
      -scheme noir \
      -configuration Release \
      -destination "platform=macOS" \
      -derivedDataPath "$DERIVED_DATA_PATH" \
      build

    APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/noir.app"
    test -d "$APP_PATH"
    test -f "$APP_PATH/Contents/Info.plist"
    test -x "$APP_PATH/Contents/MacOS/noir"

    /usr/bin/codesign --verify --deep --strict "$APP_PATH"
    /usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

    echo "$ZIP_PATH"

release:
    xcodebuild -project noir.xcodeproj -scheme noir -configuration Release -destination 'platform=macOS' build
