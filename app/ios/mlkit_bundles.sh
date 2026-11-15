#!/bin/bash
#
# Copies the ML Kit model bundles that photo check needs into the app.
#
# ML Kit comes through Swift Package Manager (d-date/google-mlkit-swiftpm),
# which can't copy the models inside its binary frameworks into the app. This
# runs as a build phase of the Runner target: it downloads the bundles once
# into ios/mlkit_bundles/ (ignored by git; Google's model files aren't
# redistributed in this repo) and copies them into the built app.
#
# Text recognition on iOS uses Apple's Vision instead (see AppDelegate.swift),
# so no OCR bundle is needed.

set -euo pipefail

VERSION="9.0.3" # the google-mlkit-swiftpm version the plugins pin
BASE_URL="https://github.com/d-date/google-mlkit-swiftpm/releases/download/${VERSION}"
CACHE="$(cd "$(dirname "$0")" && pwd)/mlkit_bundles/${VERSION}"
BUNDLES=(
  MLKitImageLabelingResources.bundle
  MLKitObjectDetectionCommonResources.bundle
)

mkdir -p "${CACHE}"
for bundle in "${BUNDLES[@]}"; do
  if [ ! -d "${CACHE}/${bundle}" ]; then
    echo "Downloading ${bundle} (ML Kit ${VERSION})"
    tmp="$(mktemp -d)"
    curl -fsSL -o "${tmp}/${bundle}.zip" "${BASE_URL}/${bundle}.zip"
    unzip -q -o "${tmp}/${bundle}.zip" -d "${tmp}"
    mv "${tmp}/${bundle}" "${CACHE}/${bundle}"
    rm -rf "${tmp}"
  fi
done

# Outside an Xcode build (run by hand), only fill the cache.
if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}" ]; then
  dest="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  for bundle in "${BUNDLES[@]}"; do
    rm -rf "${dest:?}/${bundle}"
    cp -R "${CACHE}/${bundle}" "${dest}/"
  done
fi
