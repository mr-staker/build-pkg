# frozen_string_literal: true

require 'yaml'

def build_config
  config = YAML.load_file "#{File.expand_path(__dir__)}/config.yml"
  {
    version: config[:zfs][:version],
    sha256: config[:zfs][:sha256],
    homepage: 'https://github.com/openzfs/zfs',
    maintainer: 'hello@mr.staker.ltd',
    license: 'CDDL',
    cinc: config[:versions][:cinc],
    fpm_cookery: config[:versions][:fpm_cookery]
  }
end
