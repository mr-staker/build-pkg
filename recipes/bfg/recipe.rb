# frozen_string_literal: true

require_relative '../patch'
require_relative 'metadata'

# repackage bfg as native distribution package
class Bfg < FPM::Cookery::Recipe
  homepage 'https://github.com/rtyley/bfg-repo-cleaner'
  source 'https://repo1.maven.org/maven2/com/madgag/bfg/'\
         "#{build_config[:version]}/bfg-#{build_config[:version]}.jar"
  sha256 build_config[:sha256]
  name 'bfg'
  version build_config[:version]
  description 'Removes large or troublesome blobs like git-filter-branch does,'\
              ' but faster'
  maintainer 'hello@mr.staker.ltd'
  license 'GPLv3'
  fpm_attributes({ deb_compression: 'xz', rpm_compression: 'xz' })
  depends %w[openjdk-11-jre-headless]

  # there's nothing to build
  def build; end

  def install
    mkdir_p destdir('usr/bin')
    mkdir_p destdir('usr/share/bfg')

    cp "bfg-#{build_config[:version]}.jar", destdir('usr/share/bfg/bfg.jar')
    cp workdir('rootfs/usr/bin/bfg'), destdir('usr/bin/bfg')
  end
end
