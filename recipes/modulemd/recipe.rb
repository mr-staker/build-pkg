# frozen_string_literal: true

require_relative 'metadata'

# modulemd packages recipe
class Modulemd < FPM::Cookery::Recipe
  homepage 'https://github.com/fedora-modularity/libmodulemd/'
  source 'https://github.com/fedora-modularity/libmodulemd/archive/refs/tags/'\
         "libmodulemd-#{build_config[:version]}.tar.gz"
  sha256 build_config[:sha256]
  name build_config[:name]
  version build_config[:version]
  description 'C Library for manipulating module metadata files'
  maintainer 'hello@mr.staker.ltd'
  license 'MIT'

  depends %w[
    libc6 libglib2.0-0 libffi7 libpcre3 libmagic1 librpmio8 libyaml-0-2 liblzma5
    libbz2-1.0 zlib1g libnss3 libelf1 libpopt0 libzstd1 liblua5.2-0 libnspr4
  ] + build_config[:depends]

  build_depends %w[
    meson gtk-doc-tools libglib2.0-doc gobject-introspection help2man
    libgirepository1.0-dev libc6-dev libffi-dev libpcre3-dev libmagic-dev
    librpm-dev libyaml-dev liblzma-dev libbz2-dev zlib1g-dev libnss3-dev
    libelf-dev libpopt-dev libzstd-dev liblua5.2-dev libnspr4-dev
  ]

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
        "#{destdir}/usr/share/man",
        "#{destdir}/usr/share/gtk-doc"
      ]

      lib_dirs = [
        "#{destdir}/usr/lib"
      ]

      # headers and pkgconfig
      dev_dirs = [
        "#{destdir}/usr/include",
        "#{destdir}/usr/share/gir-1.0",
        "#{destdir}/usr/lib/x86_64-linux-gnu/pkgconfig",
        "#{destdir}/usr/lib/x86_64-linux-gnu/girepository-1.0"
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

        rm_rf "#{destdir}/usr/share"
      when 'dev'
        bin_dirs.each do |dir|
          rm_rf dir
        end

        rm_rf "#{destdir}/usr/lib/python3"

        lib_files = "#{destdir}/usr/lib/x86_64-linux-gnu/libmodulemd.so*"
        Dir[lib_files].each do |file|
          rm_f file
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
end
