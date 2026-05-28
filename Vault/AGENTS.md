# Project Guidelines

## Security Principles

Read [`../MANIFESTO.md`](../MANIFESTO.md) before proposing or implementing any feature that touches killphrases, search passphrases, lock state, authentication, telemetry, backups, exports, or anything in the Danger Zone. The manifesto is normative — when a proposed change conflicts with it, the manifesto wins unless it is amended first via a dedicated `MANIFESTO:` PR.

## Testing

### Test Device Configuration

Use the simulator configuration specified in `README.md` for all builds and tests.

## Committing

Before every commit, run `make format` and `make lint` from the `Vault/` directory to ensure code is properly formatted and passes linting.
