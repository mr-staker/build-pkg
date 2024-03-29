# frozen_string_literal: true

def build_config
  config = YAML.load_file "#{File.expand_path(__dir__)}/config.yml"
  {
    version: config[:staker_repo][:version]
  }
end
