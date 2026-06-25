# betternat_runtime_artifacts

`betternat_runtime_artifacts` returns provider-supported BetterNAT runtime
artifact URLs and SHA256 checksums.

## Example Usage

```terraform
data "betternat_runtime_artifacts" "current" {
  version = "v0.1.0"
  os      = "linux"
  arch    = "arm64"
}
```

## Schema

### Required

- `version` (String) BetterNAT runtime release tag, for example `v0.1.0`.
- `os` (String) Runtime operating system. Current supported value: `linux`.
- `arch` (String) Runtime architecture. Current supported values: `amd64` and
  `arm64`.

### Read-Only

- `agent_binary_url` (String) `betternat-agent` release artifact URL.
- `agent_binary_sha256` (String) SHA256 checksum for `agent_binary_url`.
- `cli_binary_url` (String) `betternat` CLI release artifact URL.
- `cli_binary_sha256` (String) SHA256 checksum for `cli_binary_url`.
- `loxicmd_binary_url` (String) Reserved for future provider-managed `loxicmd`
  artifacts. Empty in current releases.
- `loxicmd_binary_sha256` (String) Reserved for future provider-managed
  `loxicmd` checksums. Empty in current releases.
