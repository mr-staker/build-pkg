## About

Repository hosting our fpm-cookery package build recipes.

## Common build dependencies

```bash
# install development tools and Ruby environment
curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-workstation -v 23.4.1032
eval "$(cinc shell-init zsh)" # or bash if you use it

# install Docker Desktop for Windows/Mac/Linux
# on Windows you must use the WSL2 backend
# should execute successfully - check that docker is working properly
docker info

bundle install
```

Podman may be supported as alternative to Docker. Requirements:

 * docker -> podman symlink
 * Linux build machine - either native or WSL2

Each recipe implements podman support separately. Check recipe README for confirmation whether podman is supported.

## Build recipes

 * [bfg](/recipes/bfg)
 * [createrepo](/recipes/createrepo)
 * [elrond](/recipes/elrond)
 * [hugo](/recipes/hugo)
 * [modulemd](/recipes/modulemd)
 * [staker-repo](/recipes/staker-repo)
 * [zck](/recipes/zck)
