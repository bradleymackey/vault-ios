# CryptoEngine

A simple cryptography library that implements core cryptographic operations and helpers.

For example, we vend the _scrypt_ key derivation algorithm and the AES-GCM symmetric-key cipher.
Used together, these create the basis for securing data with a simple user-known password.

This also provides the basis for 2FA TOTP codes, offering an API to generate and validate these codes.
