#!/usr/bin/env bash
# Generate stubs of ONE language.
#
#   scripts/generate.sh <lang> [out_dir]
#
# Environment:
#   PROTO_REF   semver tag being generated (required for go: selects go/ or go/vN/)
#   PROTO_DIR   proto repo root (default: parent of this script)
#   PROTOGEN_DIR / out_dir  protogen repo root (default: ../protogen, else cwd)
#   GO_MODULE, GO_DIR       override the Go layout derived from PROTO_REF
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "${script_dir}/lib.sh"

lang="${1:-}"
if [ -z "${lang}" ]; then
  echo "usage: $0 <lang> [out_dir]   (langs: ${ALL_LANGS})" >&2
  exit 2
fi
case " ${ALL_LANGS} " in
  *" ${lang} "*) ;;
  *) echo "unknown language '${lang}' (langs: ${ALL_LANGS})" >&2; exit 2 ;;
esac

proto_dir="${PROTO_DIR:-${script_dir}/..}"
proto_dir="$(cd "${proto_dir}" && pwd)"

if [ -n "${2:-}" ]; then
  mkdir -p "$2"
  out_dir="$(cd "$2" && pwd)"
elif [ -n "${PROTOGEN_DIR:-}" ]; then
  out_dir="$(cd "${PROTOGEN_DIR}" && pwd)"
elif [ -d "${proto_dir}/../protogen" ]; then
  out_dir="$(cd "${proto_dir}/../protogen" && pwd)"
else
  out_dir="$(pwd)"
fi

if [ "${lang}" = "go" ] && { [ -z "${GO_MODULE:-}" ] || [ -z "${GO_DIR:-}" ]; }; then
  go_layout "${PROTO_REF:-v0.0.0}"
fi

# buf only treats --template as a file when it has a .yaml extension.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
tmpl="${tmp_dir}/buf.gen.yaml"
render_template "${proto_dir}" "${lang}" "${tmpl}"

# Generate into a staging dir first, so a failing plugin never leaves
# the protogen checkout with its previous stubs already deleted.
stage="${tmp_dir}/stage"
mkdir -p "${stage}"
echo "generate ${lang} -> ${out_dir}/$(stub_dir "${lang}")"
( cd "${stage}" && buf generate "${proto_dir}" --template "${tmpl}" )

clean_stubs "${out_dir}" "${lang}"
mkdir -p "${out_dir}/$(stub_dir "${lang}")"
cp -R "${stage}/$(stub_dir "${lang}")/." "${out_dir}/$(stub_dir "${lang}")/"
