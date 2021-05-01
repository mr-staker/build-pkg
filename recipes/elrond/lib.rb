# frozen_string_literal: true

require 'git'
require 'json'
require 'yaml'
require 'faraday'

require_relative 'patch'

def abs_path
  File.expand_path __dir__
end

def check_release_network(networks)
  if ENV['network'].nil?
    warn 'ERR: Define the network env var e.g rake network=dev'
    Kernel.exit 1
  end

  return if networks.include? ENV['network']

  warn "ERR: Unexpected network value. Allowed: #{networks}"
  Kernel.exit 1
end

def get_url(url)
  res = Faraday.get url

  unless res.status == 200
    warn "ERR: expected status code 200 for #{url}, got #{res.status}"
    Kernel.exit 1
  end

  res.body
end

def sync_repo(base, repo)
  unless Dir.exist? repo
    puts "===> Clone #{repo}"
    Git.clone "#{base}/#{repo}", repo
  end

  puts "===> Sync #{repo}"
  g = Git.open repo
  g.pull '--rebase', '--autostash'
end

def local_clone(repo, target = nil)
  unless Dir.exist? repo
    puts "===> Local clone #{repo}"
    Git.clone "#{abs_path}/git/#{repo}", repo
  end

  g = Git.open repo

  if target
    puts "===> Checkout #{target} for #{repo}"
    g.checkout target
  end

  g
end

def go_build(name, path, args = nil)
  Dir.chdir path do
    puts "===> Build #{name} binary"
    sh "go build #{args}"
  end
end

def install_bin(repo, bin_path, bin_dir, options = {})
  cp builddir("#{repo}/#{bin_path}"), destdir(bin_dir)

  return if options[:strip] == false

  sh "strip --strip-unneeded #{destdir(bin_dir)}/#{File.basename(bin_path)}"
end

def build_config
  @config ||= YAML.load_file "#{abs_path}/build.yml"
  @config
end

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def setup_environment
  return if File.exist? 'build.yml'

  networks = {
    'main' => 'master',
    'test' => 'master',
    'dev' => 'main'
  }

  # taking the binaryVersion as the source of truth for pkg version
  bin_url = 'https://raw.githubusercontent.com/ElrondNetwork/elrond-config-'\
    "#{ENV['network']}net/#{networks[ENV['network']]}/binaryVersion"

  res = get_url bin_url
  ENV['bin_version'] = res.strip
  ENV['version'] = ENV['bin_version'].split('/').last.gsub(/[^.\d]/, '')

  # get configuration git tag/version
  cfg_url = 'https://api.github.com/repos/ElrondNetwork/elrond-config-'\
    "#{ENV['network']}net/releases/latest"
  res = get_url cfg_url

  ENV['cfg_tag'] = JSON.parse(res)['tag_name']
  ENV['cfg_version'] = ENV['cfg_tag'].split('/').last

  ENV['GOPATH'] = "#{abs_path}/go"

  # this is necessary as the environment variables are not passed down to
  # a docker container when the pkg build happens in a container
  # therefore, they must be persistent and mounted as volume
  build_config = {
    base: 'https://github.com/ElrondNetwork',
    cfg_repo: "elrond-config-#{ENV['network']}net",
    bin_repo: 'elrond-go',
    prx_repo: 'elrond-proxy-go',
    version: ENV['version'],
    network: ENV['network'],
    bin_version: ENV['bin_version'],
    cfg_version: ENV['cfg_version'],
    cfg_tag: ENV['cfg_tag']
  }

  File.write('build.yml', build_config.to_yaml)
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
def git_sync
  mkdir_p 'git'

  Dir.chdir 'git' do
    base = build_config[:base]

    sync_repo(base, build_config[:cfg_repo])
    sync_repo(base, build_config[:bin_repo])
    sync_repo(base, build_config[:prx_repo])

    # seed the go modules to avoid re-downloading them on a clean build
    Dir.chdir(build_config[:bin_repo]) do
      puts '===> Seed go modules'
      sh 'GO111MODULE=on go mod vendor'
    end
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
