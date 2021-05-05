# frozen_string_literal: true

require_relative 'metadata'

# OpenZFS build wrapper
class Zfs < FPM::Cookery::Recipe
  homepage build_config[:homepage]
  name 'zfs-dummy'
  version build_config[:version]
  description 'Dummy zfs package'
  maintainer build_config[:maintainer]
  license build_config[:license]
  source 'https://github.com/openzfs/zfs/releases/download/'\
    "zfs-#{build_config[:version]}/zfs-#{build_config[:version]}.tar.gz"
  sha256 build_config[:sha256]

  # rubocop:disable Metrics/MethodLength
  def dependency_map
    {
      'python3-pyzfs' => %w[zfs],
      'zfs-dracut' => %w[zfs-dkms],
      'zfs-initramfs' => %w[zfs-dkms],
      'zfs' => %w[zfs-dkms libnvpair3 libuutil3 libzfs4 libzpool4],
      'libzfs4-devel' => %w[libzfs4],
      'libuutil3' => [],
      'libzfs4' => [],
      'libzpool4' => [],
      'libnvpair3' => [],
      'zfs-dkms' => []
    }
  end
  # rubocop:enable Metrics/MethodLength

  def build
    pkg_type = FPM::Cookery::Facts.target
    macros_file = "#{ENV['HOME']}/.rpmmacros"
    File.write macros_file, "%_buildhost mr.staker.ltd\n"

    # for Red Hat and derivatives, this should have happen in Docker, but
    # ending up with a corrupted rpmdb
    # https://github.com/openzfs/zfs/issues/7727
    configure '--enable-systemd'
    make '-j1', "#{pkg_type}-utils", "#{pkg_type}-dkms"

    rm_f macros_file
  end

  def install
    pkg_type = FPM::Cookery::Facts.target

    mkdir_p pkgdir

    case pkg_type
    when :rpm
      install_rpm
    when :deb
      install_deb
    else
      raise "Error: unsupported target type: #{pkg_type}"
    end
  end

  def install_rpm
    macros_file = "#{ENV['HOME']}/.rpmmacros"
    File.write macros_file, "%_buildhost mr.staker.ltd\n"

    Dir['*.rpm'].each do |pkg_file|
      abs_pkg_file = File.expand_path pkg_file
      pkg_s = File.basename pkg_file, File.extname(pkg_file)
      next if File.extname(pkg_s) == '.src'

      pkg_r = File.basename pkg_s, File.extname(pkg_s)
      pkg_name = pkg_r[0..-9]

      next if pkg_name == 'zfs-test'

      Dir.chdir pkgdir do
        rm_f pkgdir("#{pkg_r}.x86_64.rpm")

        args = [
          workdir('fpm-shim').to_s,
          '--maintainer',
          build_config[:maintainer],
          '--input-type',
          'rpm',
          '--output-type',
          'rpm',
          '--architecture',
          'x86_64'
        ]

        args << abs_pkg_file

        sh(*args)
      end
    end

    rm_f macros_file
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def install_deb
    # rubocop:disable Metrics/BlockLength
    Dir['*.deb'].each do |pkg_file|
      abs_pkg_file = File.expand_path pkg_file
      pkg_name = pkg_file.split('_').first

      next if pkg_name == 'zfs-test'

      Dir.chdir pkgdir do
        # invoke a patched version of fpm to change metadata and xz compress
        # the resulting packages
        rm_f pkgdir(pkg_file)

        args = [
          workdir('fpm-shim').to_s,
          '--maintainer',
          build_config[:maintainer],
          '--input-type',
          'deb',
          '--output-type',
          'deb',
          '--license',
          build_config[:license],
          '--category',
          'optional',
          '--url',
          build_config[:homepage],
          '--deb-compression',
          'xz'
        ]

        dependency_map[pkg_name].each do |dep|
          args << '--depends'
          args << dep
        end

        args << abs_pkg_file

        sh(*args)
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
