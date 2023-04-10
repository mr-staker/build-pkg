# frozen_string_literal: true

require 'yaml'

def build_config
  config = YAML.load_file "#{File.expand_path(__dir__)}/config.yml"
  {
    version: config[:hugo][:version],
    sha256: config[:hugo][:sha256],
  }
end
