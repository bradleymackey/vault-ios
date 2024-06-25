# Vault

> WARNING: Version 1.0 has been used during initial development and is considered unstable.
> We will increment to 2.0 when the app is storage-resilient.

A secret storage manager (2FA codes, secret notes) with built-in encrypted backup.
It can backup to iCloud and paper, making it a secure, simple and robust backup solution.

Development takes place in `/Vault`, so take a look in there.

- `Vault.xcworkspace` what you should open
- `/Vault` Swift Package that defines targets used by the app, build settings, tooling.
- `/VaultApp` minimal wrapper that packages this into an executable application.

## Architecture

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

## TODO

- [x] Use a modern structure, based on SPM
  - [x] Enable Swift strict concurrency
  - [x] Enable CI for builds (#54)
- [x] OTP codes
  - [x] Create OTP storage format, stored in CoreData
  - [x] View TOTP previews
  - [x] View HOTP previews
  - [x] Show code preview in the code detail page (#59)
  - [x] Search for codes in the preview page (#67)
  - [x] Edit metadata about codes
  - [x] Import codes manually (#70)
  - [x] Import codes with camera (#71)
  - [ ] Simple widget for a single code (#69)
- [ ] Secure notes
  - [x] Create secure note storage format, stored in CoreData
  - [x] View secure note previews
  - [x] View secure note detail page (#26)
  - [x] Create secure notes from the vault home page (#64)
  - [x] Edit secure notes (#65)
- [ ] Cryptocurrency
  - [ ] Create storage format, stored in CoreData
  - [ ] View in preview
  - [ ] View detail page
  - [ ] Create from seed words
- [ ] Backup
  - [x] Create robust backup format
  - [x] Support encrypting the backup format
  - [x] Create PDF library to export backup manifest
  - [ ] User can create password, store password for encrypted backup in the keychain (#62)
  - [ ] Export PDF when a paper backup is created (#63)
  - [ ] Save backup manifest binary file to iCloud (#60)
  - [ ] Automatic sync for iCloud backup (#72)
  - [ ] Stats for last backup, in what format, when and where (#73)
  - [ ] Restore from paper backup (#74)
  - [ ] Restore from iCloud backup (#75)

## Tenets

- **Platform native**: it should look like Apple made this app.
- **Modern**: we should use modern features and push for fast deprecations.
- **Open source by default**: no binary dependencies or obfuscated stuff.
- **Robust**: test-driven development, modular PRs/commits.

## Development

The project is mostly based around the SPM package in `/Vault`.
You should be looking in there really.
As soon as we are able, we will be dropping the xcodeproj project wrapper and going all-in on the Swift Package Manager.

There's a few things to be aware of when developing and some helpful commands to ensure your code is up to scratch.

## Testing Configuration

<table>
  <tr>
	<td>Simulator for snapshot tests</td>
	<td><b>iPhone 15 on iOS 17.5</b></td>
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
