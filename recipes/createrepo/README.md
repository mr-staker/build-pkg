## About

[createrepo_c](https://github.com/rpm-software-management/createrepo_c) build for Ubuntu 22.04.

createrepo_c is the C implementation of createrepo (the traditional one being a Python 2 application which hasn't been maintained for years), a program that creates a repomd (xml-based rpm metadata) repository from a set of rpms.

This opens the door for maintaining an RPM repository from an Ubuntu 22.04 workstation. This wasn't easily doable ... until now.

## Build dependencies

```bash
# install our deb repository
# https://deb.staker.ltd/docs/intro/install-repository/
sudo apt install cmake libzck-dev libmodulemd-dev libc6-dev libglib2.0-dev libpcre3-dev libffi-dev librpm-dev python3-dev
```

These build dependencies are not available in Ubuntu 22.04 repositories, therefore these packages are provided via our own deb repository:

 * libzck-dev
 * libmodulemd-dev

The recipes for building those packages are available here:

 * [zck](../zck)
 * [modulemd](../modulemd)

## Build

```bash
bundle exec rake build:all
```

The `*_c` binaries have symlinks using their names without the `_c` suffix. For example, there's a `createrepo` symlink to `createrepo_c`.

## Publish

```bash
bundle exec rake publish:all
```
