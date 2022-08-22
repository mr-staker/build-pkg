## About

Elrond node, proxy services + tools pkg build recipe. Built on top of [fpm-cookery](https://github.com/bernd/fpm-cookery) which allows this recipe to create native packages for various Linux distributions as the underlying [fpm](https://github.com/jordansissel/fpm) build tool is very versatile.

Supports the following Linux distribution families:

 * Debian (including derivatives e.g Ubuntu) via deb packages. Built on Ubuntu 20.04.
 * Red Hat (including rebuilds e.g CentOS/Rocky/Oracle and derivatives) via rpm packages. Built on Oracle Linux 8.6.

Supports Podman build backend as alternative to Docker.

## Reasons for doing this

While the existing setup scripts are enough to get you going, that's becoming a bit difficult to maintain for an end to end automation setup. To understand this statement a bit better, shell scripts are notoriously bad/difficult at ensuring convergence/idempotence (i.e configuration management systems theory).

The binary packages have a distinct advantange w.r.t the reliability of an installation as each file has a hash in the package manifest, so this ensures that the installation is free from corruption.

 * Build once - run everywhere (assuming a supported target). This avoids hitting GitHub that often as the build only reaches out to GitHub for repo sync and to read the latest versions/tags.
 * Support more than just Ubuntu or Debian derivatives.
 * DRY codebase. The pkg build recipe is cross platform and it supports all Elrond's networks: main, test, dev. The build recipe is essentially a configurable template.
 * Template systemd units for the Elrond node and proxy services.

Our packages alone are not enough to create an Elrond node setup. It is intended to be used as part of a configuration system (e.g CINC/Chef, Ansible, etc). A [CINC/Chef cookbook](https://github.com/mr-staker/elrond-cookbook) is also provided by the same author and it uses the repositories populated by the build artefacts created by this codebase.

## How to build from scratch

There quite a few dependencies and the setup is a bit fiddly if starting from scratch.

It requires: ruby, bundler, a Docker setup capable of running volumes (preferably [in safe way](https://www.saltwaterc.eu/having-docker-socket-access-is-probably-not-a-great-idea.html) on Linux). The instructions below replicate my development setup which also require Vagrant and VirtualBox.

### Build pkg

Ultimately, if not explicitly declared, the package version is determined based on the config version for a particular network (main, test, or dev). Unless this is overridden, the default behaviour is the upstream behaviour which may have mismatches between the config version and the "binary version" - essentially which elrond-go tag a particular config is liked to.

```bash
# build everything for target network - accepts all detailed args (except image)
./buidl network=test

# build mainnet package locally i.e Ubuntu 20.04 - requires proper go setup
bundle exec rake build network=main

# a corresponding Dockerfile for the target distro must exist beforehand
# in dockerfiles

# build testnet pkg on Oracle Linux 8.6
# should also work on RHEL / what's left of CentOS
bundle exec rake build:docker network=test image=oracle:8.6

# build devnet pkg on Ubuntu 20.04
# this builds the latest pkg for the target release network (e.g dev)
# inside a Docker container using specified image
bundle exec rake build:docker network=dev image=ubuntu:20.04
```

n.b in case of version mismatch i.e binaryVersion and release tag don't match (release tag being more reliable), you can manually match them using the `bin_version` environment variable, such as:

```bash
bundle exec rake build:docker network=test image=ubuntu:20.04 bin_version=tags/v1.1.55
bundle exec rake build:docker network=test image=oracle:8.6 bin_version=tags/v1.1.55
```

With both custom `bin_version` and `cfg_tag`:

```bash
bundle exec rake build:docker network=test image=ubuntu:20.04 bin_version=tags/v1.1.57 cfg_tag=T1.1.57.0
bundle exec rake build:docker network=test image=oracle:8.6 bin_version=tags/v1.1.57 cfg_tag=T1.1.57.0
```

To combine both `bin_version` and `cfg_tag`:

```bash
bundle exec rake build:docker network=test image=ubuntu:20.04 version=1.1.57.0
bundle exec rake build:docker network=test image=oracle:8.6 version=1.1.57.0
```

Must point to a config version (without leading prefix). This example generates `bin_version=tags/v1.1.57` and `cfg_tag=T1.1.57.0` - notice the leading `T` for `cfg_tag`. For mainnet the prefix is `v` and for devnet is `D`. The prefix is automatically filled to avoid any mistakes.

To check if the versions match, read the generated `build.yml` file. This is how a properly formatted build config should look like:

```bash
---
:base: https://github.com/ElrondNetwork
:cfg_repo: elrond-config-testnet
:bin_repo: elrond-go
:prx_repo: elrond-proxy-go
:pkg_version: 1.1.51.1
:network: test
:bin_version: tags/v1.1.51
:cfg_version: T1.1.51.1
:cfg_tag: T1.1.51.1
```

To disable arwen from a build (only used on testnet so far):

```bash
bundle exec rake build:docker network=test image=ubuntu:20.04 arwen=false
bundle exec rake build:docker network=test image=oracle:8.6 arwen=false
```


Pro Tip: run the `clean` and `clean:pkg` tasks between builds to ensure you start from scratch. The repositories / go modules are cached, so the data downloaded post the initial build is fairly low. To nuke everything, there's a `clean:all` task.

```bash
bundle exec rake clean clean:pkg
```

### Print pkg info

Check deb pkg info:

```bash
dpkg --info pkg/elrond-test_1.1.51.1_amd64.deb
 new Debian package, version 2.0.
 size 20578920 bytes: control archive=1640 bytes.
      83 bytes,     2 lines      conffiles
     276 bytes,    10 lines      control
    3537 bytes,    38 lines      md5sums
 Package: elrond-test
 Version: 1.1.51.1
 License: GPLv3
 Architecture: amd64
 Maintainer: hello@mr.staker.ltd
 Installed-Size: 151031
 Section: optional
 Priority: extra
 Homepage: https://mr.staker.ltd/
 Description: Elrond Services - node and proxy + tools (3rd party package build)
```

Check rpm pkg info:

```bash
rpm -qip pkg/elrond-test-1.1.51.1-1.x86_64.rpm
Name        : elrond-test
Version     : 1.1.51.1
Release     : 1
Architecture: x86_64
Install Date: (not installed)
Group       : optional
Size        : 154610646
License     : GPLv3
Signature   : RSA/SHA512, Thu 27 May 2021 16:54:54 BST, Key ID fd6652320303527f
Source RPM  : elrond-test-1.1.51.1-1.src.rpm
Build Date  : Thu 27 May 2021 16:53:19 BST
Build Host  : 8a8f9e3bfed0
Relocations : /
Packager    : hello@mr.staker.ltd
URL         : https://mr.staker.ltd/
Summary     : Elrond Services - node and proxy + tools (3rd party package build)
Description :
Elrond Services - node and proxy + tools (3rd party package build)
```

## Package structure

The package doesn't follow the upstream organisation. It uses a traditional approach for Linux software as it obeys the [Filesystem Higherachy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard).

The current working directories are set appropriately by the systemd units for the node and proxy services. Unfortunately, the node and proxy services do not have a feature to provide a base directory for the configuration (i.e all of the config options must be specified to point to custom locations for the configuration files), so setting the appropriate CWD is the workaround here.

libwasmer should have been dealt with in a standard way via ldconfig, but ldconfig is experiencing some issues whilst trying to configure this particular library (i.e it ends up dumping a very obscure Rust error), so direct symlinking into /lib is an acceptable workaround.

Example:

```bash
/
├── etc
│   └── systemd
│       └── system
│           ├── elrond-node@.service
│           └── elrond-proxy@.service
├── lib
│   └── libwasmer_linux_amd64.so -> /opt/elrond/lib/libwasmer_linux_amd64.so
└── opt
    ├── elrond -> /opt/elrond-test-1.1.51.1
    └── elrond-test-1.1.51.1
        ├── bin
        │   ├── arwen
        │   ├── keygenerator
        │   ├── logviewer
        │   ├── node
        │   ├── proxy
        │   ├── seednode
        │   └── termui
        ├── etc
        │   └── elrond
        │       ├── node
        │       │   └── config
        │       │       ├── api.toml
        │       │       ├── binaryVersion
        │       │       ├── config.toml
        │       │       ├── docker
        │       │       │   └── Dockerfile
        │       │       ├── economics.toml
        │       │       ├── external.toml
        │       │       ├── gasSchedules
        │       │       │   ├── gasScheduleV1.toml
        │       │       │   ├── gasScheduleV2.toml
        │       │       │   └── gasScheduleV3.toml
        │       │       ├── genesisContracts
        │       │       │   ├── delegation.wasm
        │       │       │   └── dns.wasm
        │       │       ├── genesis.json
        │       │       ├── genesisSmartContracts.json
        │       │       ├── LICENSE
        │       │       ├── nodesSetup.json
        │       │       ├── p2p.toml
        │       │       ├── prefs.toml
        │       │       ├── ratings.toml
        │       │       ├── README.md
        │       │       ├── scripts
        │       │       │   └── run-observer.sh
        │       │       └── systemSmartContractsConfig.toml
        │       └── proxy
        │           └── config
        │               ├── apiConfig
        │               │   ├── credentials.toml
        │               │   ├── v1_0.toml
        │               │   └── v_next.toml
        │               ├── config.toml
        │               ├── economics.toml
        │               └── external.toml
        └── lib
            └── libwasmer_linux_amd64.so
```
