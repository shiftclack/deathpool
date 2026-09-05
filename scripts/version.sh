#!/bin/bash
VERSION="${1#v}"
TOC_FILENAME="${2}"

echo "Checking source for version '${VERSION}'..."

if [[ -z ${VERSION} ]]; then
  echo "Error: Version is empty"
  exit 1
fi

grep -q "## Version: ${VERSION}" "${TOC_FILENAME}" || {
  echo "Error: Version '${VERSION}' not found in '${TOC_FILENAME}'"
  exit 1
}

echo "All version checks passed successfully."
