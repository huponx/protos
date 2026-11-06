#!/usr/bin/env bash
# Verify the proto contracts. Rules, in order:
#   1. buf format -d --exit-code   consistent formatting
#   2. buf lint                    STANDARD rules (buf.yaml)
#   3. buf build                   everything compiles
#   4. buf breaking                only when BUF_BREAKING_AGAINST is set
#   5. trial generate              every language template into a temp dir
#
# Environment:
#   BUF_BREAKING_AGAINST  e.g. '.git#tag=v0.1.0' (empty = skip rule 4)
#   BREAKING_ACK          'true' = breaking changes are acknowledged (PR label
#                         breaking-change): report them instead of failing
#   PROTO_REF             latest released tag, selects the Go layout (default v0.0.0)
#   VERIFY_LANGS          languages to trial-generate (default: all)
#   VERIFY_SKIP_MISSING   '1' = skip a language whose local plugin is missing
#   VERIFY_GO_BUILD       '1' = also `go build` the trial Go stubs
#   GITHUB_OUTPUT         when set, writes breaking=true|false
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "${script_dir}/lib.sh"

proto_dir="$(cd "${script_dir}/.." && pwd)"
cd "${proto_dir}"

set_output() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "$1=$2" >> "${GITHUB_OUTPUT}"
  fi
}

summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n' "$@" >> "${GITHUB_STEP_SUMMARY}"
  fi
}

echo "::group::buf format"
buf format -d --exit-code
echo "::endgroup::"

echo "::group::buf lint"
buf lint
echo "::endgroup::"

echo "::group::buf build"
buf build
echo "::endgroup::"

breaking=false
if [ -n "${BUF_BREAKING_AGAINST:-}" ]; then
  echo "::group::buf breaking (against ${BUF_BREAKING_AGAINST})"
  breaking_log="$(mktemp)"
  if ! buf breaking --against "${BUF_BREAKING_AGAINST}" 2>&1 | tee "${breaking_log}"; then
    :
  fi
  # tee hides buf's exit code; a non-empty log means breaking changes were found.
  if [ -s "${breaking_log}" ]; then
    breaking=true
  fi
  echo "::endgroup::"
  if [ "${breaking}" = "true" ]; then
    summary "### Breaking changes" '```' "$(cat "${breaking_log}")" '```'
    if [ "${BREAKING_ACK:-false}" = "true" ]; then
      echo "::warning::Breaking changes found; acknowledged by the breaking-change label"
    else
      echo "::error::Breaking changes found. Fix them (add fields, deprecate, reserve, or add a v2 package) or add the 'breaking-change' label to the PR."
      set_output breaking true
      exit 1
    fi
  fi
else
  echo "buf breaking skipped (BUF_BREAKING_AGAINST is empty)"
fi
set_output breaking "${breaking}"

# Trial generation: catches plugin and template errors before protogen runs.
# Output goes to a temp dir, never into protogen.
trial() {
  local lang="$1" ref="$2" tmp
  tmp="$(mktemp -d)"
  PROTO_REF="${ref}" PROTO_DIR="${proto_dir}" bash "${script_dir}/generate.sh" "${lang}" "${tmp}"
  if [ "${lang}" = "go" ] && [ "${VERIFY_GO_BUILD:-0}" = "1" ] && command -v go >/dev/null 2>&1; then
    go_layout "${ref}"
    ( cd "${tmp}/${GO_DIR}" \
      && go mod init "${GO_MODULE}" \
      && go mod tidy \
      && go build ./... )
  fi
  rm -rf "${tmp}"
}

ref="${PROTO_REF:-v0.0.0}"
for lang in ${VERIFY_LANGS:-${ALL_LANGS}}; do
  if [ "${lang}" = "scala" ] && ! command -v protoc-gen-scala >/dev/null 2>&1; then
    if [ "${VERIFY_SKIP_MISSING:-0}" = "1" ]; then
      echo "::warning::protoc-gen-scala not on PATH; skipping scala (scripts/install-scalapb.sh)"
      continue
    fi
    echo "::error::protoc-gen-scala not on PATH (scripts/install-scalapb.sh)"
    exit 1
  fi
  echo "::group::trial generate ${lang}"
  trial "${lang}" "${ref}"
  if [ "${lang}" = "go" ]; then
    # Simulate a future major so the go/vN layout never rots unnoticed.
    trial go v2.0.0
  fi
  echo "::endgroup::"
done

echo "verify OK"
