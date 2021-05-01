## About

[(lib)modulemd](https://github.com/fedora-modularity/libmodulemd) packages for Ubuntu 20.04. Built as prerequisite for [createrepo_c](https://github.com/mr-staker/createrepo-pkg-build).

## Build dependencies

```bash
sudo apt install meson gtk-doc-tools libglib2.0-doc gobject-introspection help2man libgirepository1.0-dev libc6-dev libffi-dev libpcre3-dev libmagic-dev librpm-dev libyaml-dev liblzma-dev libbz2-dev zlib1g-dev libnss3-dev libelf-dev libpopt-dev libzstd-dev liblua5.2-dev libnspr4-dev
```

## Build

```bash
# binaries + docs
bundle exec rake build pkg=bin
# libraries
bundle exec rake build pkg=lib
# dev package - headers, pkgconfig, gobject definitions
bundle exec rake build pkg=dev
```
