#!/usr/bin/env bash
# Install protoc-gen-scala (ScalaPB) into ${1:-$HOME/.local/bin}. Needs curl and a JDK on PATH.
#
# Maven Central publishes a self-contained executable ("-unix.sh": a shell header
# in front of an assembly jar) for exactly this purpose. It needs no coursier and
# no main class, and `buf` can run it as a local plugin.
set -euo pipefail

SCALAPB_VERSION="${SCALAPB_VERSION:-0.11.17}"
dest="${1:-${HOME}/.local/bin}"
mkdir -p "${dest}"

url="https://repo1.maven.org/maven2/com/thesamet/scalapb/protoc-gen-scala/${SCALAPB_VERSION}/protoc-gen-scala-${SCALAPB_VERSION}-unix.sh"
curl -fsSL --retry 3 -o "${dest}/protoc-gen-scala" "${url}"
chmod +x "${dest}/protoc-gen-scala"

echo "installed ${dest}/protoc-gen-scala (ScalaPB ${SCALAPB_VERSION})"
