# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def build_config
  pkgs = %w[bin lib dev]

  if !pkgs.include?(ENV['pkg']) && ARGV.first != 'clean'
    raise "ERR: pkg env var must be one of: #{pkgs}"
  end

  cfg = {
    version: '0.20.0',
    sha256: 'f09034551a040ca71a8ef8a38f8e4582721ac6010f68929372639d7ec522bb95',
    pkg: ENV['pkg']
  }

  major_ver = cfg[:version].split('.').first
  base_name = 'createrepo'
  lib_name = "lib#{base_name}#{major_ver}"

  case ENV['pkg']
  when 'lib'
    cfg[:name] = lib_name
    cfg[:depends] = []
  when 'dev'
    cfg[:name] = "lib#{base_name}-dev"
    cfg[:depends] = [lib_name]
  else
    cfg[:name] = base_name
    cfg[:depends] = [lib_name]
  end

  cfg
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
