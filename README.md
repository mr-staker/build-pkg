## About

Repository hosting our fpm-cookery package build recipes.

## Common build dependencies

```bash
# install development tools and Ruby environment
curl -OL https://cinc.osuosl.org/files/unstable/cinc-workstation/21.3.346/ubuntu/20.04/cinc-workstation_21.3.346-1_amd64.deb && apt install ./cinc-workstation_21.3.346-1_amd64.deb
eval "$(cinc shell-init zsh)" # or bash if you use it
bundle install
```
