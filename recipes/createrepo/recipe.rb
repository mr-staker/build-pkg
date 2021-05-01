# frozen_string_literal: true

require_relative 'metadata'

# createrepo_c packages recipe
class Createrepo < FPM::Cookery::Recipe
  homepage 'https://github.com/rpm-software-management/createrepo_c'
  source 'https://github.com/rpm-software-management/createrepo_c/archive/'\
    "refs/tags/#{build_config[:version]}.tar.gz"
  sha256 build_config[:sha256]
  name build_config[:name]
  version build_config[:version]
  description 'C implementation of createrepo'
  maintainer 'hello@mr.staker.ltd'
  license 'GPLv2'

  # probably needless to say, but the runtime dependencies are
  # Ubuntu 20.04 specific
  depends %w[
    libzck1 libmodulemd2 libc6 libglib2.0-0 libpcre3 libffi7 librpm8
  ] + build_config[:depends]

  build_depends %w[
    cmake libzck-dev libmodulemd-dev libc6-dev libglib2.0-dev libpcre3-dev
    libffi-dev librpm-dev
  ]

  def build
    mkdir_p 'build'

    Dir.chdir 'build' do
      sh 'cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr ..'
      make
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def install
    Dir.chdir 'build' do
      make :install, 'DESTDIR' => destdir
    end

    Dir.chdir destdir('usr/bin') do
      ln_sf 'createrepo_c', 'createrepo'
      ln_sf 'mergerepo_c', 'mergerepo'
      ln_sf 'modifyrepo_c', 'modifyrepo'
      ln_sf 'sqliterepo_c', 'sqliterepo'
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

        rm_rf "#{destdir}/usr/share"
      when 'dev'
        bin_dirs.each do |dir|
          rm_rf dir
        end

        rm_rf "#{destdir}/usr/lib/python3"

        lib_files = "#{destdir}/usr/lib/x86_64-linux-gnu/libcreaterepo_c.so*"
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
