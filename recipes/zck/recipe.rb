# frozen_string_literal: true

require_relative 'metadata'

# zck packages recipe
class Zck < FPM::Cookery::Recipe
  homepage 'https://github.com/zchunk/zchunk'
  source 'https://github.com/zchunk/zchunk/archive/refs/tags/'\
         "#{build_config[:version]}.tar.gz"
  sha256 build_config[:sha256]
  name build_config[:name]
  version build_config[:version]
  description 'zchunk is a compressed file format that splits the file into '\
              'independent chunks'
  maintainer 'hello@mr.staker.ltd'
  license 'BSD-2-Clause'

  # n.b the target is Ubuntu 22.04
  depends %w[staker-repo libc6 libzstd1 libssl3] + build_config[:depends]
  build_depends %w[meson libc6-dev libzstd-dev libssl-dev]

  def build
    # the build process is the same for all packages
    sh 'meson -Dprefix=/usr build'

    Dir.chdir 'build' do
      sh 'ninja'
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def install
    Dir.chdir 'build' do
      sh "DESTDIR=#{destdir} ninja install"
    end

    # rubocop:disable Metrics/BlockLength
    Dir.chdir destdir do
      # this is the packages differentiate
      bin_dirs = [
        "#{destdir}/usr/bin",
        "#{destdir}/usr/share"
      ]

      lib_dirs = [
        "#{destdir}/usr/lib"
      ]

      # headers and pkgconfig
      dev_dirs = [
        "#{destdir}/usr/include",
        "#{destdir}/usr/lib/x86_64-linux-gnu/pkgconfig"
      ]

      case build_config[:pkg]
      when 'bin'
        (lib_dirs + dev_dirs).each do |dir|
          rm_rf dir
        end
      when 'lib'
        (bin_dirs + dev_dirs).each do |dir|
          rm_rf dir
        end
      when 'dev'
        bin_dirs.each do |dir|
          rm_rf dir
        end

        Dir["#{destdir}/usr/lib/x86_64-linux-gnu/libzck.so*"].each do |file|
          rm_f file
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
end
