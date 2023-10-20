# Vault

A secret storage manager (2FA codes, secret notes) with built-in encrypted backup.
It can backup to iCloud and paper, making it a secure, simple and robust backup solution.

Development takes place in `/Vault`, so take a look in there.

- `Vault.xcworkspace` what you should open
- `/Vault` Swift Package that defines targets used by the app, build settings, tooling.
- `/VaultApp` minimal wrapper that packages this into an executable application.

## Tenets

![Tenet](https://media.tenor.com/bcOXw06JhO8AAAAC/tenet-hands.gif)

- Platform native, it should look like Apple made this app.
- Open source by default, no binary dependencies or obfuscated stuff.
- Test-driven development.
