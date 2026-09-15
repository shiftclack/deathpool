#!/bin/bash
version="${1#v}"
toc_filename="${2}"
constants_filename="${3}"

if [[ -z $version || -z $toc_filename || -z $constants_filename  ]]; then
    echo "syntax: $0 <version> <toc_filename> <constants_filename>"
    exit 1
fi

grep -Fxq "## Version: ${version}" "${toc_filename}" || {
    echo "precondition failure: version ${version} not found in ${toc_filename}"
    exit 1
}

grep -q "VERSION = \"0\\.0\\.0\",$" "${constants_filename}" || {
    echo "precondition failure: version is not set to 0.0.0 in ${constants_filename}"
    exit 1
}

sed -i.bak "s/VERSION = \"0\\.0\\.0\",$/VERSION = \"${version}\",/" "${constants_filename}" || {
    echo "error: version ${version} could not be set in ${constants_filename}"
    exit 1
}

grep -q "VERSION = \"${version}\",$" "${constants_filename}" || {
    echo "error: version ${version} not substituted successfully in ${constants_filename}"
    exit 1
}

rm -f "${constants_filename}.bak"
