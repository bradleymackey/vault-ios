# Vault

A secret storage manager (2FA codes, secret notes) with built-in encrypted backup.
It can backup to iCloud and paper, making it a secure, simple and robust backup solution.

Development takes place in `/Vault`, so take a look in there.

- `Vault.xcworkspace` what you should open
- `/Vault` Swift Package that defines targets used by the app, build settings, tooling.
- `/VaultApp` minimal wrapper that packages this into an executable application.

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
	<td><b>iPhone 15 on iOS 17.4</b></td>
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
