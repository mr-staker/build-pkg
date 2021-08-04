# frozen_string_literal: true

require 'fpm/package/deb'

module FPM
  module Cookery
    # monkey patch fpm-cook to allow for custom docker image tagging when
    # --dockerfile is used
    class DockerPackager
      # long method to patch is long
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def run
        recipe_dir = File.dirname(recipe.filename)

        # The cli settings should have precendence
        image_name = config.docker_image || recipe.docker_image
        cache_paths = get_cache_paths
        dockerfile = get_dockerfile(recipe_dir)

        if File.exist?(dockerfile)
          image_name ||= "local/fpm-cookery/#{File.basename(recipe_dir)}:latest"

          Log.info "Building custom Docker image #{image_name} from "\
            "#{dockerfile}"

          build_cmd = [
            config.docker_bin, 'build',
            '-f', dockerfile,
            '-t', image_name,
            '--force-rm',
            '.'
          ].compact.flatten.join(' ')
          sh build_cmd
        else
          Log.warn "File #{dockerfile} does not exist - not building a "\
            'custom Docker image'
        end

        if image_name.nil? || image_name.empty?
          image_name = "fpmcookery/#{FPM::Cookery::Facts.platform}-"\
            "#{FPM::Cookery::Facts.osrelease}:#{FPM::Cookery::VERSION}"
        end

        Log.info "Building #{recipe.name}-#{recipe.version} inside a "\
          "Docker container using image #{image_name}"
        Log.info "Mounting #{recipe_dir} as /recipe"

        cmd = [
          config.docker_bin, 'run', '-ti',
          '--name', "fpm-cookery-build-#{File.basename(recipe_dir)}",
          config.docker_keep_container ? nil : '--rm',
          '-e', "FPMC_UID=#{Process.uid}",
          '-e', "FPMC_GID=#{Process.gid}",
          config.debug ? ['-e', 'FPMC_DEBUG=true'] : nil,
          build_cache_mounts(cache_paths),
          '-v', "#{recipe_dir}:/recipe",
          '-w', '/recipe',
          image_name,
          'fpm-cook', 'package', '--no-deps',
          config.debug ? '-D' : nil,
          File.basename(recipe.filename)
        ].compact.flatten.join(' ')

        Log.debug "Running: #{cmd}"
        begin
          sh cmd
        rescue StandardError => e
          Log.debug e
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end

  class Package
    # building an xz deb is a bit broken as control.tar.gz is hardcoded and ar
    # bails out for obvious reasons
    # rubocop:disable Metrics/ClassLength
    class Deb < FPM::Package
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def write_control_tarball
        # Use custom Debian control file when given ...
        write_control # write the control file
        write_shlibs # write optional shlibs file
        write_scripts # write the maintainer scripts
        write_conffiles # write the conffiles
        write_debconf # write the debconf files
        write_meta_files # write additional meta files
        write_triggers # write trigger config to 'triggers' file
        write_md5sums # write the md5sums file

        # Tar up the staging_path into control.tar.{compression type}
        case attributes[:deb_compression]
        when 'gz', nil
          controltar = build_path('control.tar.gz')
          compression = '-z'
        when 'bzip2'
          controltar = build_path('control.tar.bz2')
          compression = '-j'
        when 'xz'
          controltar = build_path('control.tar.xz')
          compression = '-J'
        when 'none'
          controltar = build_path('control.tar')
          compression = ''
        else
          raise FPM::InvalidPackageConfiguration,
                "Unknown compression type '#{attributes[:deb_compression]}'"
        end

        logger.info('Creating', path: controltar, from: control_path)

        # set max compression for xz
        args = [
          { 'XZ_DEFAULTS' => '-T 0 -9' },
          tar_cmd, '-C', control_path, compression, '-cf', controltar,
          '--owner=0', '--group=0', '--numeric-owner', '.'
        ]
        if tar_cmd_supports_sort_names_and_set_mtime? && \
           !attributes[:source_date_epoch].nil?
          # Force deterministic file order and timestamp
          args += [
            '--sort=name', format('--mtime=@%s', attributes[:source_date_epoch])
          ]
          # gnu tar obeys GZIP environment variable with options for gzip;
          # -n = forget original filename and date
          # args.unshift({"GZIP" => "-9n"})
        end
        safesystem(*args)

        controltar

        # logger.debug(
        #   'Removing no longer needed control dir', path: control_path
        # )
      ensure
        FileUtils.rm_r(control_path)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # good thing this method isn't long
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def output(output_path)
        self.provides = provides.collect { |p| fix_provides(p) }
        output_check(output_path)
        # Abort if the target path already exists.

        # create 'debian-binary' file, required to make a valid debian package
        File.write(build_path('debian-binary'), "2.0\n")

        # If we are given --deb-shlibs but no --after-install script, we
        # should implicitly create a before/after scripts that run ldconfig
        if attributes[:deb_shlibs]
          unless script?(:after_install)
            logger.info('You gave --deb-shlibs but no --after-install, so ' \
                         'I am adding an after-install script that runs ' \
                         'ldconfig to update the system library cache')
            scripts[:after_install] = template(
              'deb/ldconfig.sh.erb'
            ).result(binding)
          end
          unless script?(:after_remove)
            logger.info('You gave --deb-shlibs but no --after-remove, so ' \
                         'I am adding an after-remove script that runs ' \
                         'ldconfig to update the system library cache')
            scripts[:after_remove] = template(
              'deb/ldconfig.sh.erb'
            ).result(binding)
          end
        end

        if attributes[:source_date_epoch].nil? && \
           !attributes[:source_date_epoch_default].nil?
          source_date = :source_date_epoch_default
          attributes[:source_date_epoch] = attributes[source_date]
        end
        if attributes[:source_date_epoch] == '0'
          logger.error(
            %(Alas, ruby's Zlib::GzipWriter does not support setting an mtime)\
            ' of zero.  Aborting.'
          )
          raise "#{name}: source_date_epoch of 0 not supported."
        end
        if !attributes[:source_date_epoch].nil? && !ar_cmd_deterministic?
          logger.error(
            'Alas, could not find an ar that can handle -D option. '\
            'Try installing recent gnu binutils. Aborting.'
          )
          raise "#{name}: ar is insufficient to support source_date_epoch."
        end
        if !attributes[:source_date_epoch].nil? && \
           !tar_cmd_supports_sort_names_and_set_mtime?
          logger.error(
            'Alas, could not find a tar that can set mtime and sort. '\
            'Try installing recent gnu tar. Aborting.'
          )
          raise "#{name}: tar is insufficient to support source_date_epoch."
        end

        attributes.fetch(:deb_systemd_list, []).each do |systemd|
          name = File.basename(systemd, '.service')
          dest_systemd = staging_path("lib/systemd/system/#{name}.service")
          mkdir_p(File.dirname(dest_systemd))
          FileUtils.cp(systemd, dest_systemd)
          File.chmod(0o644, dest_systemd)

          # set the attribute with the systemd service name
          attributes[:deb_systemd] = name
        end

        if script?(:before_upgrade) || script?(:after_upgrade) || \
           attributes[:deb_systemd]
          puts 'Adding action files'
          if script?(:before_install) || script?(:before_upgrade)
            scripts[:before_install] = template(
              'deb/preinst_upgrade.sh.erb'
            ).result(binding)
          end
          if script?(:before_remove) || attributes[:deb_systemd]
            scripts[:before_remove] = template(
              'deb/prerm_upgrade.sh.erb'
            ).result(binding)
          end
          if script?(:after_install) || script?(:after_upgrade) || \
             attributes[:deb_systemd]
            scripts[:after_install] = template(
              'deb/postinst_upgrade.sh.erb'
            ).result(binding)
          end
          if script?(:after_remove)
            scripts[:after_remove] = template(
              'deb/postrm_upgrade.sh.erb'
            ).result(binding)
          end

          if script?(:after_purge)
            scripts[:after_purge] = template(
              'deb/postrm_upgrade.sh.erb'
            ).result(binding)
          end
        end

        # There are two changelogs that may appear:
        #   - debian-specific changelog, which should be archived as
        #     changelog.Debian.gz
        #   - upstream changelog, which should be archived as changelog.gz
        # see https://www.debian.org/doc/debian-policy/ch-docs.html#s-changelogs

        # Write the changelog.Debian.gz file
        dest_changelog = File.join(
          staging_path, "usr/share/doc/#{name}/changelog.Debian.gz"
        )
        mkdir_p(File.dirname(dest_changelog))
        File.new(dest_changelog, 'wb', 0o644).tap do |changelog|
          best_comp = Zlib::BEST_COMPRESSION
          Zlib::GzipWriter.new(changelog, best_comp).tap do |changelog_gz|
            unless attributes[:source_date_epoch].nil?
              changelog_gz.mtime = attributes[:source_date_epoch].to_i
            end
            if attributes[:deb_changelog]
              logger.info(
                'Writing user-specified changelog',
                source: attributes[:deb_changelog]
              )
              chunk = nil
              File.new(attributes[:deb_changelog]).tap do |fd|
                # Ruby 1.8.7 doesn't have IO#copy_stream
                changelog_gz.write(chunk) while (chunk = fd.read(16_384))
              end.close
            else
              logger.info('Creating boilerplate changelog file')
              changelog_gz.write(template('deb/changelog.erb').result(binding))
            end
          end.close
        end

        # Write the changelog.gz file (upstream changelog)
        dest_upstream_changelog = File.join(
          staging_path, "usr/share/doc/#{name}/changelog.gz"
        )
        if attributes[:deb_upstream_changelog]
          best_comp = Zlib::BEST_COMPRESSION
          File.new(dest_upstream_changelog, 'wb', 0o644).tap do |changelog|
            Zlib::GzipWriter.new(changelog, best_comp).tap do |changelog_gz|
              unless attributes[:source_date_epoch].nil?
                changelog_gz.mtime = attributes[:source_date_epoch].to_i
              end
              logger.info(
                'Writing user-specified upstream changelog',
                source: attributes[:deb_upstream_changelog]
              )
              chunk = nil
              File.new(attributes[:deb_upstream_changelog]).tap do |fd|
                # Ruby 1.8.7 doesn't have IO#copy_stream
                changelog_gz.write(chunk) while (chunk = fd.read(16_384))
              end.close
            end.close
          end
        end

        # see https://www.debian.org/doc/debian-policy/ch-docs.html#s-changelogs
        if File.exist?(dest_changelog) && !File.exist?(dest_upstream_changelog)
          File.rename(dest_changelog, dest_upstream_changelog)
        end

        attributes.fetch(:deb_init_list, []).each do |init|
          name = File.basename(init, '.init')
          dest_init = File.join(staging_path, "etc/init.d/#{name}")
          mkdir_p(File.dirname(dest_init))
          FileUtils.cp init, dest_init
          File.chmod(0o755, dest_init)
        end

        attributes.fetch(:deb_default_list, []).each do |default|
          name = File.basename(default, '.default')
          dest_default = File.join(staging_path, "etc/default/#{name}")
          mkdir_p(File.dirname(dest_default))
          FileUtils.cp default, dest_default
          File.chmod(0o644, dest_default)
        end

        attributes.fetch(:deb_upstart_list, []).each do |upstart|
          name = File.basename(upstart, '.upstart')
          dest_init = staging_path("etc/init.d/#{name}")
          name = "#{name}.conf" unless name =~ /\.conf$/
          dest_upstart = staging_path("etc/init/#{name}")
          mkdir_p(File.dirname(dest_upstart))
          FileUtils.cp(upstart, dest_upstart)
          File.chmod(0o644, dest_upstart)

          # Install an init.d shim that calls upstart
          mkdir_p(File.dirname(dest_init))
          FileUtils.ln_s('/lib/init/upstart-job', dest_init)
        end

        attributes.fetch(:deb_systemd_list, []).each do |systemd|
          name = File.basename(systemd, '.service')
          dest_systemd = staging_path("lib/systemd/system/#{name}.service")
          mkdir_p(File.dirname(dest_systemd))
          FileUtils.cp(systemd, dest_systemd)
          File.chmod(0o644, dest_systemd)
        end

        controltar = write_control_tarball

        # Tar up the staging_path into data.tar.{compression type}
        case attributes[:deb_compression]
        when 'gz', nil
          datatar = build_path('data.tar.gz')
          compression = '-z'
        when 'bzip2'
          datatar = build_path('data.tar.bz2')
          compression = '-j'
        when 'xz'
          datatar = build_path('data.tar.xz')
          compression = '-J'
        else
          raise FPM::InvalidPackageConfiguration,
                "Unknown compression type '#{attributes[:deb_compression]}'"
        end

        # set max compression for xz
        args = [{ 'XZ_DEFAULTS' => '-T 0 -9' }, tar_cmd, '-C', staging_path,
                compression] + data_tar_flags + ['-cf', datatar, '.']
        if tar_cmd_supports_sort_names_and_set_mtime? && \
           !attributes[:source_date_epoch].nil?
          # Use gnu tar options to force deterministic file order and timestamp
          args += [
            '--sort=name', format('--mtime=@%s', attributes[:source_date_epoch])
          ]
          # gnu tar obeys GZIP environment variable with options for gzip;
          # -n = forget original filename and date
          # args.unshift({ 'GZIP' => '-9n' })
        end
        safesystem(*args)

        # pack up the .deb, which is just an 'ar' archive with 3 files
        # the 'debian-binary' file has to be first
        File.expand_path(output_path).tap do |out_path|
          ::Dir.chdir(build_path) do
            safesystem(*ar_cmd, out_path, 'debian-binary', controltar, datatar)
          end
        end

        # if a PACKAGENAME.changes file is to be created
        return unless attributes[:deb_generate_changes?]

        distribution = attributes[:deb_dist]

        # gather information about the files to distribute
        files = [output_path]
        changes_files = []
        files.each do |path|
          changes_files.push({
                               name: path,
                               size: File.size?(path),
                               md5sum: Digest::MD5.file(path).hexdigest,
                               sha1sum: Digest::SHA1.file(path).hexdigest,
                               sha256sum: Digest::SHA2.file(path).hexdigest
                             })
        end

        # write change infos to .changes file
        changes_path = "#{File.basename(output_path, '.deb')}.changes"
        changes_data = template('deb/deb.changes.erb').result(binding)
        File.write(changes_path, changes_data)
        logger.log('Created changes', path: changes_path)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
    # rubocop:enable Metrics/ClassLength
  end
end
