## About

Repository hosting our fpm-cookery package build recipes.

## Common build dependencies

```bash
# install development tools and Ruby environment
curl -OL https://cinc.osuosl.org/files/unstable/cinc-workstation/21.3.346/ubuntu/20.04/cinc-workstation_21.3.346-1_amd64.deb && apt install ./cinc-workstation_21.3.346-1_amd64.deb
eval "$(cinc shell-init zsh)" # or bash if you use it

# Ubuntu 20.04 example
# Docker for Windows/Mac is recommended for those platforms - jump to docker info
# Bear in mind that Docker for Windows/Mac requires your code directory to be shared with the Docker VM
# Docker setup - Ubuntu 20.04
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

# disable docker daemon - only the client is relevant
sudo systemctl stop docker
sudo systemctl disable docker

# setup this Docker VM https://github.com/SaltwaterC/kitchen-docker-host-vagrant
# don't forget to create a volumes.yml file to be able to build the code
# mounting your code directory into the Docker VM is mandatory

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
