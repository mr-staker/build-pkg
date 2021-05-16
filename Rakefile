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
  desc 'Build package'
  task :default do
    recipe_dir
    target = ''
    target = "--target #{ENV['target']}" unless ENV['target'].nil?
    sh "fpm-cook package --no-deps #{target}"
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

  desc 'Build the package in Vagrant'
  task :vagrant do
    recipe_dir

    sh 'vagrant up'

    build = 'cd /recipe && /opt/cinc/embedded/bin/fpm-cook package --no-deps'
    sh %(vagrant ssh -c 'sudo su - -c "#{build}"')
  end
end
# rubocop:enable Metrics/BlockLength

task build: %w[build:default]

# rubocop:disable Metrics/BlockLength
namespace :clean do
  desc 'Clean build files'
  task :default do
    recipe_dir
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

  desc 'Clean Vagrant box'
  task :vagrant do
    sh 'vagrant destroy -f'
    rm_rf '.vagrant'
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

namespace :publish do
  desc 'Setup publish targets'
  task :setup do
    recipe_dir
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

task publish: %w[publish:default]
task lint: %i[cop]

desc 'Default task - invoke build'
task default: %w[build:default]
