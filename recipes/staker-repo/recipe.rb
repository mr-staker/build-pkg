# frozen_string_literal: true

require_relative 'patch'

# Mr Staker repository configuration and signing keys
class StakerRepo < FPM::Cookery::Recipe
  homepage 'https://mr.staker.ltd'
  name 'staker-repo'
  version '21.04.02'
  description 'Repository configuration and signing keys'
  maintainer 'hello@mr.staker.ltd'
  license 'MIT'
  # the noop handler doesn't run the install method, hence placing a dummy
  source 'cache/dummy.tar.gz'
  # this is the dummy file hash to make fpm-cook shut up about pkg source
  sha256 '73462d8e7fb2b65a354d365f607b6c7bbd2ef10dd17fe68d4a9aa8a66ebce8d3'

  def self.signing_keys
    Dir.chdir workdir 'rootfs' do
      Dir['**/*.pem'].map { |e| "/#{e}" }
    end
  end

  fpm_attributes({ deb_no_default_config_files?: true })
  config_files signing_keys
  directories %w[/etc/staker-repo]

  # there's nothing to build
  def build; end

  def install
    cp_r workdir('rootfs/etc'), destdir

    case FPM::Cookery::Facts.target
    when :deb
      install_deb
    when :rpm
      install_rpm
    else
      raise "Error: unsupported target #{FPM::Cookery::Facts.target}"
    end
  end

  # rubocop:disable Metrics/MethodLength
  def install_deb
    mkdir_p destdir 'etc/apt/sources.list.d'
    mkdir_p destdir 'usr/share/keyrings'

    cp(
      workdir('assets/deb/config/staker.list'),
      destdir('etc/apt/sources.list.d')
    )

    # build keyring
    Dir["#{destdir('etc/staker-repo')}/*.pem"].each do |sign_key|
      sh 'gpg --no-default-keyring --keyring='\
         "#{destdir('usr/share/keyrings/staker-keyring.gpg')} --import "\
         "#{sign_key}"
    end
  end
  # rubocop:enable Metrics/MethodLength

  def install_rpm
    mkdir_p destdir 'etc/yum.repos.d'

    cp(
      workdir('assets/rpm/config/staker.repo'),
      destdir('etc/yum.repos.d')
    )
  end
end
