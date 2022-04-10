## About

The purpose of this project is to build the Mr Staker repository package.

This package is managing the configuration file of the repository itself and the GPG signing keys to allow for automatic upgrades/key rotation in the future.

The versioning scheme is YY.MM.VV where YY is the year expressed as the last 2 digits, MM is the month express in 2 digits (leading 0 included if Jan-Sep), and VV is a release number starting with 01. The release number is 01 in most cases, unless there's more than one release in a given YY.MM time frame.

## Build

```bash
bundle exec rake build:docker image=ubuntu:20.04
bundle exec rake build:docker image=oracle:8.5
```

## Test

```bash
bundle exec rake test image=ubuntu:20.04
bundle exec rake test image=oracle:8.5
```
