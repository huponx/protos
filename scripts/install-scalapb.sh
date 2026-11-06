#!/usr/bin/env bash
# Install protoc-gen-scala (ScalaPB) into ${1:-$HOME/.local/bin}. Needs coursier (`cs`).
set -euo pipefail

SCALAPB_VERSION="${SCALAPB_VERSION:-0.11.17}"
dest="${1:-${HOME}/.local/bin}"
mkdir -p "${dest}"
cs bootstrap --standalone "com.thesamet.scalapb:protoc-gen-scala:${SCALAPB_VERSION}" \
  -o "${dest}/protoc-gen-scala" -f
echo "installed ${dest}/protoc-gen-scala (ScalaPB ${SCALAPB_VERSION})"
