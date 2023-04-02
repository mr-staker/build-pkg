## About

[zfs](https://github.com/openzfs/zfs/) deb/rpm packages. They don't really use `fpm-cookery` to build the packages themselves i.e they are built by the `make` targets provided by the zfs source.

`fpm-cookery` is only used as a wrapper to maintain the same build framework the rest of the packages do.

Supports Podman build backend as alternative to Docker.

## Build

```bash
bundle exec rake build:all # default build mode

# alternative build modes
# deb
bundle exec rake clean
bundle exec rake build:config
bundle exec rake build # deb - native
# rpm
bundle exec rake clean
bundle exec rake build:config
bundle exec rake build:vagrant # rpm - inside a VM
# test build results
bundle exec rake test:all
```
