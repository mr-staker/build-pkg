# frozen_string_literal: true

require_relative '../patch'
require_relative 'metadata'

# repackage Hugo binary release
class Hugo < FPM::Cookery::Recipe
  homepage 'https://github.com/gohugoio/hugo'
  source 'https://github.com/gohugoio/hugo/releases/download/'\
         "v#{build_config[:version]}/"\
         "hugo_extended_#{build_config[:version]}_Linux-64bit.tar.gz"
  sha256 build_config[:sha256]
  name 'hugo'
  version build_config[:version]
  description 'A Fast and Flexible Static Site Generator'
  maintainer 'hello@mr.staker.ltd'
  license 'Apache License 2.0'
  depends %w[staker-repo]

  fpm_attributes({ deb_compression: 'xz', rpm_compression: 'xz' })

  # there's nothing to build
  def build; end

  def install
    mkdir_p destdir('usr/bin')
    cp 'hugo', destdir('usr/bin')
  end
end
