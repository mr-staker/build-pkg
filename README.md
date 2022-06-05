## About

Repository hosting our fpm-cookery package build recipes.

## Common build dependencies

```bash
# install development tools and Ruby environment
curl -OL https://cinc.osuosl.org/files/unstable/cinc-workstation/22.1.745/ubuntu/20.04/cinc-workstation_22.1.745-1_amd64.deb && apt install ./cinc-workstation_22.1.745-1_amd64.deb
eval "$(cinc shell-init zsh)" # or bash if you use it

# install Docker Desktop for Windows/Mac/Linux
# on Windows you must use the WSL2 backend
# should execute successfully - check that docker is working properly
docker info

bundle install
```

## Build recipes

 * [bfg](/recipes/bfg)
 * [createrepo](/recipes/createrepo)
 * [elrond](/recipes/elrond)
 * [hugo](/recipes/hugo)
 * [modulemd](/recipes/modulemd)
 * [staker-repo](/recipes/staker-repo)
 * [zck](/recipes/zck)
