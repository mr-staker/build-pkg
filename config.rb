# frozen_string_literal: true

require 'faraday'

def get_url(url)
  res = Faraday.get url

  unless res.status == 200
    warn "ERR: expected status code 200 for #{url}, got #{res.status}"
    Kernel.exit 1
  end

  res.body
end

def build_pkg_config
  vars_url = 'https://raw.githubusercontent.com/multiversx/mx-chain-scripts/master/config/variables.cfg'
  vars = get_url vars_url

  {
    versions: {
      rocky: '9.1',
      ubuntu: '22.04',
      cinc: '18.2.7', # kept in sync with CINC Workstation
      serverspec: '2.42.2',
      fpm_cookery: '0.37.0',
      go: vars.match(/GO_LATEST_TESTED="go(.*?)"/)[1]
    },
    bfg: {
      version: '1.14.0',
      sha256: '1a75e9390541f4b55d9c01256b361b815c1e0a263e2fb3d072b55c2911ead0b7',
    },
    createrepo: {
      version: '0.20.1',
      sha256: 'f9d025295f15169ef0767460faa973aebbfb2933a55ded9500c50435c650eadc',
    },
    hugo: {
      version: '0.111.3',
      sha256: 'b382aacb522a470455ab771d0e8296e42488d3ea4e61fe49c11c32ec7fb6ee8b',
    },
    modulemd: {
      version: '2.14.0',
      sha256: '219bca4797a3de74ee961c0252067654e6ca5414e22610db7924826b1895e369',
    },
    staker_repo: {
      version: '23.04.02',
    },
    zck: {
      version: '1.3.0',
      sha256: '5563baa254b256e30e1fea87f94f53a5cf63a074898644f3f7ae5b58f446db03',
    },
    zfs: {
      version: '2.1.11',
      sha256: 'a54fe4e854d0a207584f1799a80e165eae66bc30dc8e8c96a1f99ed9d4d8ceb2',
    }
  }
end
