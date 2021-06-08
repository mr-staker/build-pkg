# frozen_string_literal: true

require_relative 'lib'

setup_environment unless ARGV.first == 'clean'

# fpm-cookery recipe for building elrond-node native packages
# rubocop:disable Metrics/ClassLength
class Elrond < FPM::Cookery::Recipe
  homepage 'https://mr.staker.ltd/'

  # this is just a stub source as the actual code is fetched from GitHub
  source 'cache/dummy.tar.gz'
  # this is the dummy file hash to make fpm-cook shut up about pkg source
  sha256 '73462d8e7fb2b65a354d365f607b6c7bbd2ef10dd17fe68d4a9aa8a66ebce8d3'

  name pkg_name
  conflicts pkg_conflicts

  # this is set dynamically based on target network - prepared by rake rask
  version build_config[:pkg_version]
  description 'Elrond Services - node and proxy + tools '\
    '(3rd party package build)'

  config_files %w[
    /etc/systemd/system/elrond-node@.service
    /etc/systemd/system/elrond-proxy@.service
  ]

  maintainer 'hello@mr.staker.ltd'
  license 'GPLv3'

  fpm_attributes({ deb_compression: 'xz', rpm_compression: 'xz' })

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def build
    Dir.chdir workdir do
      git_sync
    end

    puts "===> Build in #{Dir.pwd}"

    Dir.chdir builddir do
      puts "===> Build in #{Dir.pwd}"

      local_clone build_config[:cfg_repo], build_config[:cfg_tag]
      bin_git = local_clone build_config[:bin_repo], build_config[:bin_version]
      local_clone build_config[:prx_repo]

      tag_id = bin_git.describe('HEAD', tags: true, long: true)[-10, 11]

      Dir.chdir build_config[:bin_repo] do
        puts "===> Build in #{Dir.pwd}"
        puts '===> Download go modules'

        sh 'GO111MODULE=on go mod vendor'

        go_build 'node', 'cmd/node', "-v -ldflags='-X main.appVersion="\
          "#{build_config[:cfg_version]}-0-#{tag_id}'"

        if arwen?
          go_build 'arwen', '.', '-o ./arwen github.com/ElrondNetwork/'\
            'arwen-wasm-vm/cmd/arwen'
        end

        go_build 'termui', 'cmd/termui'
        go_build 'logviewer', 'cmd/logviewer'
        go_build 'seednode', 'cmd/seednode'
        go_build 'keygenerator', 'cmd/keygenerator'
        go_build 'assessment', 'cmd/assessment'
      end

      Dir.chdir build_config[:prx_repo] do
        puts "===> Build in #{Dir.pwd}"
        go_build 'proxy', 'cmd/proxy'
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # instead of "make install" this is merely copying the binaries and service
  # unit to the expected tmp build path which replicates the actual rootfs path
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def install
    puts "===> Build in #{Dir.pwd}"
    puts '===> Run Elrond install into destdir'

    dest_path = "opt/#{name}-#{build_config[:pkg_version]}"
    sysd_path = 'etc/systemd/system'

    # create system path
    mkdir_p destdir(sysd_path) # systemd units

    # create optware
    etc_dir = "#{dest_path}/etc"
    bin_dir = "#{dest_path}/bin"
    lib_dir = "#{dest_path}/lib"

    mkdir_p destdir("#{etc_dir}/elrond/node")
    mkdir_p destdir("#{etc_dir}/elrond/proxy")
    mkdir_p destdir(bin_dir)
    mkdir_p destdir(lib_dir)
    mkdir_p destdir('lib')

    Dir.chdir destdir('opt') do
      puts "===> Build in #{Dir.pwd}"
      ln_sf "/#{dest_path}", 'elrond'
    end

    # copy binaries
    binaries = %w[
      cmd/node/node
      cmd/termui/termui
      cmd/logviewer/logviewer
      cmd/seednode/seednode
      cmd/keygenerator/keygenerator
      cmd/assessment/assessment
    ]

    binaries << 'arwen' if arwen?

    binaries.each do |bin_path|
      install_bin build_config[:bin_repo], bin_path, bin_dir
    end

    # copy Elrond proxy
    install_bin build_config[:prx_repo], 'cmd/proxy/proxy', bin_dir

    # copy libwasmer - for the time being, only Linux/amd64 is supported
    lib_file = 'libwasmer_linux_amd64.so'
    lib_path = 'vendor/github.com/ElrondNetwork/arwen-wasm-vm/wasmer/'\
      "#{lib_file}"
    # object stripping is unreliable on Ubuntu 18.04
    install_bin build_config[:bin_repo], lib_path, lib_dir, strip: false

    # link into /lib as ldconfig behaves weirdly under Ubuntu 18.04
    # this avoids messing with ldconfig
    Dir.chdir destdir('lib') do
      puts "===> Build in #{Dir.pwd}"
      ln_sf "/opt/elrond/lib/#{lib_file}", lib_file
    end

    # copy systemd units
    Dir.chdir workdir do
      puts "===> Build in #{Dir.pwd}"

      elrond_node_svc = file_template(
        "rootfs/#{sysd_path}/elrond-node@.service", arwen: arwen?
      )
      File.write(destdir("#{sysd_path}/elrond-node@.service"), elrond_node_svc)

      cp "rootfs/#{sysd_path}/elrond-proxy@.service", destdir(sysd_path)
    end

    # copy elrond network configuration
    cp_r(
      builddir(build_config[:cfg_repo]),
      destdir("#{etc_dir}/elrond/node/config")
    )
    rm_rf destdir("#{etc_dir}/elrond/node/config/.git")

    # copy proxy configuration
    cp_r(
      builddir("#{build_config[:prx_repo]}/cmd/proxy/config"),
      destdir("#{etc_dir}/elrond/proxy/config")
    )

    # copy assessment testdata
    cp_r(
      builddir("#{build_config[:bin_repo]}/cmd/assessment/testdata"),
      destdir("#{etc_dir}/elrond/testdata")
    )
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
# rubocop:enable Metrics/ClassLength
