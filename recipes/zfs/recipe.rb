# frozen_string_literal: true

require_relative 'metadata'

# OpenZFS build wrapper
# rubocop:disable Metrics/ClassLength
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
  def deb_dependency_map
    {
      'python3-pyzfs' => %w[libzfs4 python3 staker-repo],
      'zfs-dracut' => %w[zfs zfs-dkms staker-repo],
      'zfs-initramfs' => %w[zfs zfs-dkms staker-repo],
      'zfs' => %w[zfs-dkms libnvpair3 libuutil3 libzfs4 libzpool4 staker-repo],
      'libzfs4-devel' => %w[libzfs4 staker-repo],
      'libuutil3' => %w[libc6 staker-repo],
      'libzfs4' => %w[
        libssl1.1 zlib1g libuuid1 libblkid1 libudev1 libc6 zfs-dkms staker-repo
      ],
      'libzpool4' => %w[
        libc6 libzfs4 libnvpair3 libuuid1 libblkid1 libudev1 staker-repo
      ],
      'libnvpair3' => %w[libc6 staker-repo],
      'zfs-dkms' => %w[dkms staker-repo]
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

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def install_rpm
    macros_file = "#{ENV['HOME']}/.rpmmacros"
    File.write macros_file, "%_buildhost mr.staker.ltd\n"

    skip_pkg = %w[
      zfs-test zfs-test-debuginfo libzpool4-debuginfo libuutil3-debuginfo
      zfs-debuginfo libnvpair3-debuginfo libzfs4-debuginfo zfs-debugsource
    ]

    # rubocop:disable Metrics/BlockLength
    Dir['*.rpm'].each do |pkg_file|
      abs_pkg_file = File.expand_path pkg_file
      pkg_s = File.basename pkg_file, File.extname(pkg_file)

      next if File.extname(pkg_s) == '.src'

      pkg_r = File.basename pkg_s, File.extname(pkg_s)
      pkg_b = File.basename pkg_r, File.extname(pkg_r)

      pkg_name = pkg_b[0..-9]
      arch = File.extname pkg_s

      next if skip_pkg.include? pkg_name

      if arch == '.x86_64'
        puts "===> Copy #{pkg_name}"
        cp abs_pkg_file, pkgdir

        next
      end

      puts "===> Repackage #{pkg_name}"

      Dir.chdir pkgdir do
        rm_f pkgdir("#{pkg_r}.x86_64.rpm")

        args = [
          '/opt/chef/embedded/bin/fpm',
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
    # rubocop:enable Metrics/BlockLength

    rm_f macros_file
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def install_deb
    # rubocop:disable Metrics/BlockLength
    Dir['*.deb'].each do |pkg_file|
      abs_pkg_file = File.expand_path pkg_file
      pkg_name = pkg_file.split('_').first

      next if pkg_name == 'zfs-test'

      puts "===> Repackage #{pkg_name}"

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

        deb_dependency_map[pkg_name].each do |dep|
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
# rubocop:enable Metrics/ClassLength
