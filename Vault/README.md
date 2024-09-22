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
