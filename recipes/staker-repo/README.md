## About

The purpose of this project is to build the Mr Staker repository package.

This package is managing the configuration file of the repository itself and the GPG signing keys to allow for automatic upgrades/key rotation in the future.

The versioning scheme is YY.MM.VV where YY is the year expressed as the last 2 digits, MM is the month express in 2 digits (leading 0 included if Jan-Sep), and VV is a release number starting with 01. The release number is 01 in most cases, unless there's more than one release in a given YY.MM time frame.

Build dependencies:

```bash
# install development tools and Ruby environment
curl -OL https://cinc.osuosl.org/files/unstable/cinc-workstation/21.3.346/ubuntu/20.04/cinc-workstation_21.3.346-1_amd64.deb && apt install ./cinc-workstation_21.3.346-1_amd64.deb
eval "$(cinc shell-init zsh)" # or bash if you use that

bundle install
```

## Build

```bash
# build deb - assumes Debian/Debian-derrivative distro
bundle exec rake build
```
