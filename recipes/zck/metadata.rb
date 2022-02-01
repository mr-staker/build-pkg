# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def build_config
  pkgs = %w[bin lib dev]

  if !pkgs.include?(ENV['pkg']) && ARGV.first != 'clean'
    raise "ERR: pkg env var must be one of: #{pkgs}"
  end

  cfg = {
    version: '1.1.16',
    sha256: '33934adecddc50c64615dd8cdfe52a79df674a5bb1d5e83a9c09e1d1e6e9b92c',
    pkg: ENV['pkg']
  }

  major_ver = cfg[:version].split('.').first
  base_name = 'zck'
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
