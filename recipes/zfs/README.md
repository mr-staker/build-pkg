## About

[zfs](https://github.com/openzfs/zfs/) deb/rpm packages. They don't really use `fpm-cookery` to build the packages themselves i.e they are built by the `make` targets provided by the zfs source.

`fpm-cookery` is only used as a wrapper to maintain the same build framework the rest of the packages do.

## Build dependencies

```bash
sudo apt install curl ca-certificates build-essential git autoconf automake libtool gawk alien fakeroot dkms rpm python3 python3-setuptools python3-cffi python3-distlib python3-packaging linux-headers-virtual libblkid-dev uuid-dev libudev-dev libssl-dev zlib1g-dev libaio-dev libattr1-dev libelf-dev python3-dev libffi-dev
```

## Build

```bash
bundle exec rake build # deb
bundle exec rake build:vagrant # rpm

bundle exec rake build:docker image=ubuntu:20.04 # alternative deb build - e.g on WSL2
bundle exec rake build:docker image=oracle:8.6 # alternative rpm build - e.g on WSL2
```

Pro tip: Clean the project in between the builds (won't touch build artefacts).

```bash
bundle exec rake clean
```
