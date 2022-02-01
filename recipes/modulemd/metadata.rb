# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def build_config
  pkgs = %w[bin lib dev]

  if !pkgs.include?(ENV['pkg']) && ARGV.first != 'clean'
    raise "ERR: pkg env var must be one of: #{pkgs}"
  end

  cfg = {
    version: '2.13.0',
    sha256: '2941bc44e79a9de8f1e562d599c0b9077d2f1c3d801f1be381255c42a40b31df',
    pkg: ENV['pkg']
  }

  major_ver = cfg[:version].split('.').first
  base_name = 'modulemd'
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
