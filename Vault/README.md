# Vault Package

Vault package that contains the library for the Vault app.
It's a Swift package that defines several targets, ultimately vended via `VaultiOS` to the application wrapper.

## Architecture

There's essentially 3 storage representations, which we encode and decode from.

To avoid exponential growth of encoders and decoders between all the formats, we always only encode and decode to the Application Layer `VaultItem`.
This gives us a common format and source of truth for fields that should be present in all the other formats.

```
                               ┌────────────────┐
                               │                │
                               │  Application   │
                            ┌─▶│  Layer         │◀─┐
                            │  │                │  │
                            │  │  [VaultItem]   │  │
                            │  └────────────────┘  │
                            │                      │
                            │                      │
                            │                      │
                            │                      │
┌─────────────────────────┐ │                      │    ┌────────────────────┐
│                         │ │                      │    │                    │
│  Persistence            │ │                      │    │ Backup             │
│  Layer (SwiftData)      │◀┘                      └──▶ │ Layer              │
│                         │                             │                    │
│  [PersistedVaultItem]   │                             │ [VaultBackupItem]  │
└─────────────────────────┘                             └────────────────────┘
```

## Key Derivation

Once defined, a key deriver's composition can never be changed for backwards compatibility.
Vault defines some standard key derivers that are used by default to create encryption keys for encrypting vault backups.

In the case of a composition key deriver: the output at each step is directed as an input to the next step.

These derivers are benchmarked via `make benchmark-keygen`, so you can see their performance on your machine.

| Key Deriver | Signature                        | Purpose                                    |
| ----------- | -------------------------------- | ------------------------------------------ |
| Fast V1     | `vault.keygen.default.fast-v1`   | Derivation for `DEBUG` builds              |
| Secure V1   | `vault.keygen.default.secure-v1` | Derivation for production `RELEASE` builds |

### Fast V1

A composition key deriver, using the same salt at each step, in this order:

1. PBKDF2, 256 bit key length, SHA2 (SHA384), 2000 iterations
2. HKDF, 256 bit key length, SHA3 (SHA512)
3. scrypt, 256 bit key length, N = 1 << 6, r = 4, p = 1

### Secure V1

A composition key deriver, using the same salt at each step, in this order:

1. PBKDF2, 256 bit key length, SHA2 (SHA384), 5452351 iterations
2. HKDF, 256 bit key length, SHA3 (SHA512)
3. scrypt, 256 bit key length, N = 1 << 18, r = 8, p = 1

## Testing Configuration

<table>
  <tr>
	<td>Simulator for snapshot tests</td>
	<td><b>iPhone 16 on iOS 18.0</b></td>
  </tr>
</table>

Simulator configuration, such as setting locale is covered by the use of test plans.
You shouldn't need to manually change the locale or any other simulator setting for the tests to pass.

## Development Workflow

<table>
  <tr>
	<td>Format Sources</td>
	<td><b>make format</b></td>
  </tr>
  <tr>
	<td>Lint Sources</td>
	<td><b>make lint</b></td>
  </tr>
  <tr>
	<td>Force clean existing build artifacts</td>
	<td><b>make clean</b></td>
  </tr>
</table>
