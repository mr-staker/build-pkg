## About

[zfs](https://github.com/openzfs/zfs/) deb/rpm packages. They don't really use `fpm-cookery` to build the packages themselves i.e they are built by the `make` targets provided by the zfs source.

`fpm-cookery` is only used as a wrapper to maintain the same build framework the rest of the packages do.

## Build dependencies

```bash
sudo apt install build-essential autoconf automake libtool gawk alien fakeroot dkms libblkid-dev uuid-dev libudev-dev libssl-dev zlib1g-dev libaio-dev libattr1-dev libelf-dev linux-headers-$(uname -r) python3 python3-dev python3-setuptools python3-cffi libffi-dev dkms rpm alien
```

## Build

```bash
bundle exec rake build # deb
bundle exec rake build:vagrant # rpm
```
