# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def build_config
  pkgs = %w[bin lib dev]

  if !pkgs.include?(ENV['pkg']) && ARGV.first != 'clean'
    raise "ERR: pkg env var must be one of: #{pkgs}"
  end

  cfg = {
    version: '0.18.0',
    sha256: 'd1bb142c7f88e5aa4db71cf21992beb2ad65a9b88a8d3ba459fcc6f0a4fba54f',
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
