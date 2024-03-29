# frozen_string_literal: true

require_relative 'patch'
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
      'python3-pyzfs' => %w[libzfs5 python3 staker-repo],
      'zfs-dracut' => %w[zfs zfs-dkms staker-repo],
      'zfs-initramfs' => %w[zfs zfs-dkms staker-repo],
      'zfs' => %w[zfs-dkms libnvpair3 libuutil3 libzfs5 libzpool5 staker-repo],
      'libzfs5-devel' => %w[libzfs5 staker-repo],
      'libuutil3' => %w[libc6 staker-repo],
      'libzfs5' => %w[
        libssl3 zlib1g libuuid1 libblkid1 libudev1 libc6 zfs-dkms staker-repo
      ],
      'libzpool5' => %w[
        libc6 libzfs5 libnvpair3 libuuid1 libblkid1 libudev1 staker-repo
      ],
      'libnvpair3' => %w[libc6 staker-repo],
      'zfs-dkms' => %w[dkms staker-repo]
    }
  end
  # rubocop:enable Metrics/MethodLength

  def patch_disable_tests
    # slim tests to avoid zfs-dkms growing too big and going over
    # the Cloudflare Pages limit of 25 MiB per file
    patch workdir('patches/disable.tests.Makefile.am.patch'), 1
    patch workdir('patches/disable.tests.zfs.spec.in.patch'), 1
    patch workdir('patches/disable.tests.configure.ac.patch'), 1
  end

  def build
    pkg_type = FPM::Cookery::Facts.target
    rpmmacros = "#{ENV['HOME']}/.rpmmacros"
    puts "==> Write #{rpmmacros}"
    File.write rpmmacros, "%_buildhost mr.staker.ltd\n"

    patch_disable_tests
    sh './autogen.sh'
    rm_rf 'tests'

    # for Red Hat and derivatives, this should have happen in Docker, but
    # ending up with a corrupted rpmdb
    # https://github.com/openzfs/zfs/issues/7727
    configure '--enable-systemd'
    make '-j1', "#{pkg_type}-utils", "#{pkg_type}-dkms"

    rm_f rpmmacros
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
      zfs-test zfs-test-debuginfo libzpool5-debuginfo libuutil3-debuginfo
      zfs-debuginfo libnvpair3-debuginfo libzfs5-debuginfo zfs-debugsource
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
        # invoke fpm to change metadata and xz compress
        # the resulting packages
        rm_f pkgdir(pkg_file)

        use_pkg_name = pkg_name
        if pkg_name.end_with?('devel')
          use_pkg_name = pkg_name.sub('devel', 'dev')
        end

        args = [
          '/opt/chef/embedded/bin/fpm',
          '--name',
          use_pkg_name,
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
