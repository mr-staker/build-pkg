# frozen_string_literal: true

require 'erb'
require 'yaml'

build_pkg_root = File.dirname(File.realpath(__FILE__))
docker_img_prefix = 'local/build-pkg'

require "#{build_pkg_root}/config"

# Openstruct/ERB wrapper
class Template
  def initialize(hash)
    hash.each do |key, value|
      instance_variable_set('@' + key.to_s, value)
      create_attr key
    end
  end

  def create_method(name, &block)
    self.class.send(:define_method, name, &block)
  end

  def create_attr(name)
    create_method( name.to_sym ) do
      instance_variable_get("@" + name.to_s)
    end
  end

  def render(template)
    ERB.new(template).result(binding)
  end
end

def recipe_dir(root)
  return if File.exist? 'recipe.rb'

  if ENV['recipe'].nil?
    warn 'ERR: unable to detect recipe and no "recipe" env var declared'
    Kernel.exit 1
  end

  Dir.chdir "#{root}/recipes/#{ENV['recipe']}"
end

def check_publisher
  if ENV['target'].nil?
    warn 'ERR: unspecified target e.g deb or rpm'
    Kernel.exit 1
  end

  return unless ENV['repo'].nil?

  warn 'ERR: unspecified repo where to publish packages'
  Kernel.exit 1
end

def clean_dummies
  Dir['pkg/*dummy*'].each do |pkg|
    rm_f pkg
  end
end

desc 'Run rubocop'
task :cop do
  sh 'rubocop'
end

# rubocop:disable Metrics/BlockLength
namespace :build do
  desc 'Dump config as yaml into recipe dir'
  task :config do
    recipe_dir build_pkg_root
    File.write 'config.yml', build_pkg_config.to_yaml
  end

  desc 'Invoke recipe build script'
  task all: %w[build:config] do
    recipe_dir build_pkg_root
    sh './build'
  end

  desc 'Build package'
  task :default do
    recipe_dir build_pkg_root
    target = ''
    target = "--target #{ENV['target']}" unless ENV['target'].nil?
    sh "fpm-cook package --no-deps #{target}"
  end

  desc 'Build Dockerfile from template'
  task :template do
    if ENV['image'].nil?
      warn 'ERR: a Docker image must be specified'
      Kernel.exit 1
    end

    dockerfile = "#{build_pkg_root}/docker/files/#{ENV['image']}"
    template_file = "#{build_pkg_root}/docker/templates/#{ENV['image']}.erb"

    if File.exist? dockerfile
      next
    end

    template_contents = File.read(template_file)
    dockerfile_contents = Template.new(build_pkg_config).render(template_contents)
    File.write(dockerfile, dockerfile_contents)
  end

  desc 'Build the package in Docker'
  task :docker do
    recipe_dir build_pkg_root
    Rake::Task['build:template'].invoke
    dockerfile = "#{build_pkg_root}/docker/files/#{ENV['image']}"
    sh 'bundle exec fpm-cook package --no-deps --docker '\
       "--dockerfile #{dockerfile} "\
       "--docker-image #{docker_img_prefix}/#{ENV['image']}"
  end

  desc 'Build the package in Vagrant'
  task :vagrant do
    recipe_dir build_pkg_root

    sh 'vagrant up'

    build = 'cd /recipe && /opt/cinc/embedded/bin/fpm-cook package --no-deps'
    sh "vagrant ssh -c '#{build}'"
  end
end
# rubocop:enable Metrics/BlockLength

task build: %w[build:default]

# rubocop:disable Metrics/BlockLength
namespace :clean do
  desc 'Clean build files'
  task :default do
    recipe_dir build_pkg_root
    sh 'sudo rm -rf tmp-build'
    rm_rf 'tmp-dest'
    rm_f 'build.yml'
  end

  desc 'Clean build artefacts'
  task :pkg do
    recipe_dir build_pkg_root
    rm_rf 'pkg'
  end

  desc 'Clean Docker images'
  task :docker do
    cmd = "docker images -qf 'reference=#{docker_img_prefix}/*'"
    `#{cmd}`.split("\n").each do |img|
      sh "docker rmi #{img}"
    end
  end

  desc 'Clean Vagrant box'
  task :vagrant do
    sh 'vagrant destroy -f'
    rm_rf '.vagrant'
  end

  desc 'Clean Dockerfiles generated from templates'
  task :dockerfiles do
    rm_rf "#{build_pkg_root}/docker/files"
    mkdir_p "#{build_pkg_root}/docker/files"
    touch "#{build_pkg_root}/docker/files/.gitkeep"
  end

  desc 'Remove all build files'
  task all: %w[clean:default clean:pkg clean:dockerfiles] do
    recipe_dir build_pkg_root
    rm_rf 'cache' unless File.exist? 'cache/dummy.tar.gz'
    rm_rf 'go'
    rm_rf 'git'
  end
end
# rubocop:enable Metrics/BlockLength

task clean: %w[clean:default]

namespace :publish do
  desc 'Invoke recipe publish script'
  task :all do
    recipe_dir build_pkg_root
    sh './publish'
  end

  desc 'Setup publish targets'
  task :setup do
    recipe_dir build_pkg_root
    check_publisher
    clean_dummies
  end

  desc 'Add packages to local repository via repo-mgr'
  task default: %w[publish:setup] do
    Dir["pkg/*.#{ENV['target']}"].each do |pkg|
      puts "===> Publish #{File.basename pkg}"
      sh "repo-mgr add-pkg --repo #{ENV['repo']} --path #{pkg}"
    end
  end

  desc 'Sync published packages using repo-mgr publisher'
  task sync: %w[publish:setup publish:default] do
    sh "repo-mgr sync --repo #{ENV['repo']}"
  end

  desc 'Remove published packages from local repository via repo-mgr'
  task undo: %w[publish:setup] do
    Dir["pkg/*.#{ENV['target']}"].each do |pkg|
      puts "===> Unpublish #{File.basename pkg}"
      sh "repo-mgr remove-pkg --repo #{ENV['repo']} --path #{pkg}"
    end
  end
end

# rubocop:disable Metrics/BlockLength
namespace :test do
  desc 'Copy upstream test to recipe dir'
  task :copy do
    recipe_dir build_pkg_root
    %w[spec_helper.rb size_spec.rb].each do |file|
      cp "#{build_pkg_root}/spec/#{file}", "spec/#{file}"
    end
  end

  desc 'Invoke test script from recipe dir'
  task all: %w[test:copy] do
    recipe_dir build_pkg_root
    sh './test'
  end

  task :init do
    if ENV['image'].nil?
      warn 'ERR: a Docker image must be specified'
      Kernel.exit 1
    end

    @container = "build-#{File.basename(Dir.pwd)}-#{ENV['image'].tr(':', '-')}"
    @image = "#{docker_img_prefix}/#{ENV['image']}"
  end

  desc 'Setup test environment'
  task setup: %w[test:init] do
    recipe_dir build_pkg_root

    system "docker rm -f #{@container}"
    sh "docker run --volume #{Dir.pwd}:/build --name #{@container} "\
       "--detach #{@image} tail -f /dev/null"
  end

  desc 'Install package in container'
  task install: %w[test:init] do
    recipe_dir build_pkg_root

    sh "docker exec #{@container} /build/install"
  end

  desc 'Run test suite for recipe'
  task run: %w[test:init] do
    recipe_dir build_pkg_root

    unless Dir.exist? 'spec'
      warn 'The spec dir is missing - unable to run tests'
      Kernel.exit 1
    end

    sh "docker exec --env IN_DOCKER=1 #{@container} /build/test"
  end

  desc 'Tear down test environment'
  task clean: %w[test:init] do
    recipe_dir build_pkg_root

    sh "docker rm -f #{@container}"
  end

  desc 'Run recipe specific test suite'
  task default: %w[test:setup test:install test:run test:clean]
end
# rubocop:enable Metrics/BlockLength

task test: %w[test:default]

task publish: %w[publish:default]
task lint: %i[cop]

task build: %w[build:default]

desc 'Default task - invoke build'
task default: %w[build:all]
