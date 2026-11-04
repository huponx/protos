# protos

gRPC contracts (`.proto` only). Generated stubs live in `protogen`.

```
ping/v1/ping.proto
```

Add a new API by adding `bill/v1/bill.proto` here — do not create a new repo.

## Verify

`buf lint` + `buf build` check that `.proto` files parse and follow [lint](buf.yaml). `buf breaking` compares against the previous semver tag (`FILE` rules). Skipped on the first tag, and when **Run workflow** uses bump `major`.

```bash
bash proto/scripts/verify.sh
# optional: BUF_BREAKING_AGAINST='.git#tag=v0.1.0' bash proto/scripts/verify.sh
```

## Versioning

[verify-release](.github/workflows/verify-release.yml) runs on push/`pull_request` to `main`, and on **Run workflow** (bump `patch` / `minor` / `major`).

- Verify always (`lint` + `build`; breaking when a previous tag exists).
- After a successful verify on `main`, auto-create the next semver tag (first tag is `v0.1.0`, later pushes default to **patch**). `pull_request` verifies only. Push with no `.proto` / `buf.yaml` / `buf.gen.yaml` changes does not tag.
- Creating that tag starts [notify-protogen](.github/workflows/notify-protogen.yml), which sends `repository_dispatch` to `protogens` with `proto_ref` and `proto_repo`.

Re-notify an existing tag: **Run workflow** on notify-protogen and set `proto_ref` (e.g. `v0.2.0`).

Secret on this repo: `PROTOGEN_DISPATCH_TOKEN`.  
Optional variable: `PROTOGEN_REPO` (default `huponx/protogen`).

`GITHUB_TOKEN` of proto cannot dispatch another repo. Create a **fine-grained PAT** (or GitHub App) and grant it **on `protogen`**, not proto:

- Repository access: only `protogen`
- **Contents: Read and write** (required for `POST /repos/.../dispatches`)
- **Actions: Read and write**
- Metadata: Read (selected automatically)

Job outputs and summary: `proto_ref`, `proto_repo`, `target_repo`, `dispatched`.

## Local

Generate with [`buf.gen.yaml`](buf.gen.yaml) and [`scripts/generate.sh`](scripts/generate.sh). Output is written into `protogen` (`out: go` → `protogen/go`).

```bash
make generate
# or: PROTO_DIR=proto PROTOGEN_DIR=protogen bash proto/scripts/generate.sh
```

To add a language: enable a plugin in `buf.gen.yaml`. The `protogen` workflow only needs extra tool setup and `git add` if required.
