# frozen_string_literal: true

require_relative 'config'

source 'https://rubygems.org'

gem 'faraday'
gem 'fpm', git: 'https://github.com/SaltwaterC/fpm' # fixes lack of zstd compression
gem 'fpm-cookery', "= #{build_pkg_config[:versions][:fpm_cookery]}"
gem 'git'
gem 'pry'
gem 'rake'
gem 'repo-mgr', '= 0.3.1'
gem 'rubocop'
gem 'serverspec', "= #{build_pkg_config[:versions][:serverspec]}"
