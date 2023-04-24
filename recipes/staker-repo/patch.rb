# frozen_string_literal: true

require 'json/version'
require 'json/generic_object'

# patch JSON parser 1.8.6 to work with Ruby 3
module JSON
  class << self
    def parse(source, _opts = {})
      Parser.new(source).parse
    end
  end
end

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
                       "#{FPM::Cookery::Facts.osrelease}:"\
                       "#{FPM::Cookery::VERSION}"
        end

        Log.info "Building #{recipe.name}-#{recipe.version} inside a "\
                 "Docker container using image #{image_name}"
        Log.info "Mounting #{recipe_dir} as /recipe"

        user = Process.uid
        group = Process.gid

        if File.exist? '/usr/bin/podman'
          # Podman runs rootless so root inside the container
          # is actually user:group on host
          user = 0
          group = 0
        end

        cmd = [
          config.docker_bin, 'run', '-ti',
          '--name', "fpm-cookery-build-#{File.basename(recipe_dir)}",
          config.docker_keep_container ? nil : '--rm',
          '-e', "FPMC_UID=#{Process.uid}",
          '-e', "FPMC_GID=#{Process.gid}",
          '--user', "#{user}:#{group}",
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
end
