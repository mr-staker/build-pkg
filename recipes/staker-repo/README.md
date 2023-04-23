## About

The purpose of this project is to build the Mr Staker repository package.

This package is managing the configuration file of the repository itself and the GPG signing keys to allow for automatic upgrades/key rotation in the future.

The versioning scheme is YY.MM.VV where YY is the year expressed as the last 2 digits, MM is the month express in 2 digits (leading 0 included if Jan-Sep), and VV is a release number starting with 01. The release number is 01 in most cases, unless there's more than one release in a given YY.MM time frame.

Supports Podman build backend as alternative to Docker.

## Build

```bash
bundle exec rake build:all
```

## New key

```bash
gpg --full-generate-key
# RSA and RSA
# 4096
# Release Signing Key $YEAR # as comment
# 3 years expiration
```

## Export public key

```bash
gpg --list-secret-keys --keyid-format=long
[...]
sec   rsa4096/$KEY_ID
[...]
gpg --armor --export $KEY_ID
```

## Export private key

```bash
gpg --list-secret-keys --keyid-format=long
[...]
sec   rsa4096/$KEY_ID
      $KEY_ID_LONG
[...]
gpg --export-secret-keys $KEY_ID_LONG > $KEY_ID.key
```
