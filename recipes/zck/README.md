## About

[zchunk (zck)](https://github.com/zchunk/zchunk) packages for Ubuntu 20.04. Built as prerequisite for [createrepo_c](https://github.com/mr-staker/createrepo-pkg-build).

## Build dependencies

```bash
sudo apt install meson libc6-dev libzstd-dev libssl-dev
```

## Build

```bash
# binaries + docs
bundle exec rake build pkg=bin
# library
bundle exec rake build pkg=lib
# dev package - header and pkgconfig
bundle exec rake build pkg=dev
```
