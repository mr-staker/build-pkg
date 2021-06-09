# frozen_string_literal: true

require 'erb'
require 'git'
require 'json'
require 'yaml'
require 'faraday'

require_relative 'patch'

def abs_path
  File.expand_path __dir__
end

def networks
  %w[main test dev]
end

def network_branch
  {
    'main' => 'master',
    'test' => 'master',
    'dev' => 'main'
  }
end

def network_prefix
  {
    'main' => 'v',
    'test' => 'T',
    'dev' => 'D'
  }
end

def pkg_name
  "elrond-#{build_config[:network]}"
end

def pkg_conflicts
  (networks - [build_config[:network]]).map { |net| "elrond-#{net}" }
end

def check_release_network(cmd = 'rake')
  if ENV['network'].nil?
    warn "ERR: Define the network env var e.g #{cmd} network=dev"
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

def gen_version
  return unless ENV['version']

  ENV['bin_version'] = "tags/v#{ENV['version'][0..-3]}"
  ENV['cfg_tag'] = "#{network_prefix[ENV['network']]}#{ENV['version']}"
end

def tag_sha
  # fetch tag info
  tag_url = 'https://api.github.com/repos/ElrondNetwork/elrond-config-'\
    "#{ENV['network']}net/git/ref/tags/#{ENV['cfg_tag']}"
  tag = get_url tag_url

  ENV['cfg_sha'] = JSON.parse(tag)['object']['sha']
end

def gen_cfg_version
  if ENV['cfg_tag'].nil?
    # get configuration git tag/version
    cfg_url = 'https://api.github.com/repos/ElrondNetwork/elrond-config-'\
      "#{ENV['network']}net/releases/latest"
    cfg = get_url cfg_url

    ENV['cfg_tag'] = JSON.parse(cfg)['tag_name']
    tag_sha
  end

  ENV['cfg_version'] = ENV['cfg_tag'].split('/').last
  ENV['pkg_version'] = ENV['cfg_version'][1..-1]
end

# rubocop:disable Metrics/MethodLength
def bin_url
  # taking the binaryVersion as the source of truth for pkg version
  if ENV['cfg_sha']
    # bust cache - read from commit URL
    url = 'https://raw.githubusercontent.com/ElrondNetwork/'\
      "elrond-config-#{ENV['network']}net/#{ENV['cfg_sha']}/binaryVersion"
  else
    url = 'https://raw.githubusercontent.com/ElrondNetwork/elrond-config-'\
      "#{ENV['network']}net/#{network_branch[ENV['network']]}/binaryVersion"

    warn ''
    warn 'WARNING: no cfg_sha env var - using default binaryVersion URL.'
    warn 'WARNING: This may be cached by GitHub!'
    warn ''
  end

  url
end
# rubocop:enable Metrics/MethodLength

def gen_bin_version
  return unless ENV['bin_version'].nil?

  res = get_url bin_url
  ENV['bin_version'] = res.strip
end

def fetch_versions(cmd = 'rake')
  check_release_network cmd

  gen_version
  gen_cfg_version
  gen_bin_version
end

# rubocop:disable Metrics/MethodLength
def setup_environment
  return if File.exist? 'build.yml'

  fetch_versions

  ENV['GOPATH'] = "#{abs_path}/go"

  # this is necessary as the environment variables are not passed down to
  # a docker container when the pkg build happens in a container
  # therefore, they must be persistent and mounted as volume
  build_config = {
    base: 'https://github.com/ElrondNetwork',
    cfg_repo: "elrond-config-#{ENV['network']}net",
    bin_repo: 'elrond-go',
    prx_repo: 'elrond-proxy-go',
    pkg_version: ENV['pkg_version'],
    network: ENV['network'],
    bin_version: ENV['bin_version'],
    cfg_version: ENV['cfg_version'],
    cfg_tag: ENV['cfg_tag']
  }

  File.write('build.yml', build_config.to_yaml)
end
# rubocop:enable Metrics/MethodLength

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

def arwen?
  # (ab)using Gem::Version to do a general version comparison to determine
  # whether to build arwen or not
  Gem::Version.new(build_config[:pkg_version]) < Gem::Version.new('1.1.60.0')
end

def file_template(file, vars)
  ERB.new(File.read(file), nil, '-').result_with_hash(vars)
end

# extract args as env vars to mimic rake behaviour
def extract_args
  ARGV.each do |arg|
    arg = arg.split '='
    ENV[arg.first] = arg.last
  end
end

def buidl_cmd_append(arg)
  return "#{arg}=#{ENV['arg']}" if ENV[arg]

  ''
end

def clean
  Kernel.system 'rake clean'
end

def buidl(img)
  buidl_cmd = "rake build:docker image=#{img} network=#{ENV['network']}"
  %w[version bin_version cfg_tag].each { |arg| buidl_cmd_append arg }

  status = Kernel.system buidl_cmd

  Kernel.exit 1 unless status
end
