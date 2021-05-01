# frozen_string_literal: true

docker_img_prefix = 'local/build-pkg'

def recipe_dir
  return if File.exist? 'recipe.rb'

  if ENV['recipe'].nil?
    warn 'ERR: unable to detect recipe and no "recipe" env var declared'
    Kernel.exit 1
  end

  Dir.chdir "recipes/#{ENV['recipe']}"
end

desc 'Run rubocop'
task :cop do
  sh 'rubocop'
end

namespace :build do
  desc 'Build package'
  task :default do
    recipe_dir
    sh 'fpm-cook package --no-deps'
  end

  desc 'Build the package in Docker'
  task :docker do
    recipe_dir

    dockerfile = "dockerfiles/#{ENV['image']}"
    dockerfile = "../../#{dockerfile}" unless File.exist? dockerfile

    if ENV['image'].nil?
      warn 'ERR: a Docker image must be specified'
      Kernel.exit 1
    elsif !File.exist? dockerfile
      warn "ERR: missing #{dockerfile}"
      Kernel.exit 1
    end

    sh "bundle exec fpm-cook package --docker --dockerfile #{dockerfile} "\
      "--docker-image #{docker_img_prefix}/#{ENV['image']}"
  end
end

task build: %w[build:default]

# rubocop:disable Metrics/BlockLength
namespace :clean do
  desc 'Clean build files'
  task :default do
    recipe_dir
    sh 'fpm-cook clean'
    rm_rf 'tmp-build'
    rm_rf 'tmp-dest'
    rm_f 'build.yml'
  end

  desc 'Clean build artefacts'
  task :pkg do
    recipe_dir
    rm_rf 'pkg'
  end

  desc 'Clean Docker images'
  task :docker do
    cmd = "docker images -qf 'reference=#{docker_img_prefix}/*'"
    `#{cmd}`.split("\n").each do |img|
      sh "docker rmi #{img}"
    end
  end

  desc 'Remove all build files'
  task all: %w[clean:default clean:pkg] do
    recipe_dir
    rm_rf 'cache' unless File.exist? 'cache/dummy.tar.gz'
    rm_rf 'go'
    rm_rf 'git'
  end
end
# rubocop:enable Metrics/BlockLength

task clean: %w[clean:default]

desc 'Default task - invoke build'
task default: %w[build:default]
