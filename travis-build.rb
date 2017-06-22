#!/usr/bin/env ruby

require 'bundler'
require 'pathname'
require 'time'

# ########################################
# Constants

PROJECTS = %w[
  stash-wrapper
  stash-harvester
  stash-sword
  stash-merritt
  stash_engine
  stash_engine_specs
  stash_discovery
  stash_datacite
  stash_datacite_specs
].freeze

STASH_ROOT = Pathname.new(__dir__).realpath

TRAVIS_PREP_SH = 'travis-prep.sh'.freeze

IN_TRAVIS = ENV['TRAVIS'] == 'true' ? true : false

# ########################################
# Accessors

def successful_builds
  @successful_builds ||= []
end

def failed_builds
  @failed_builds ||= []
end

# ########################################
# Helper methods

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text)
  colorize(text, 31)
end

def green(text)
  colorize(text, 32)
end

def yellow(text)
  colorize(text, 33)
end

def tmp_path
  @tmp_path ||= begin
    tmp_path = STASH_ROOT + 'builds' + Time.now.utc.iso8601
    tmp_path.mkpath
    tmp_path
  end
end

def working_path
  Pathname.getwd.relative_path_from(STASH_ROOT)
end

def run_task(task_name, shell_command)
  if IN_TRAVIS
    travis_fold(task_name) do
      puts "#{working_path}: #{yellow(shell_command)}"
      return system(shell_command)
    end
  end

  log_file = tmp_path + "#{task_name}.out"
  build_ok = redirect_to(shell_command, log_file)
  return build_ok if build_ok

  $stderr.puts("#{shell_command} failed")
  system("cat #{log_file}")

  false
end

def travis_fold(task_name)
  puts "travis_fold:start:#{task_name}"
  yield
ensure
  puts "travis_fold:end:#{task_name}"
end

def script_command(shell_command, log_file)
  return "script -q #{log_file} #{shell_command} > /dev/null" if /(darwin|bsd)/ =~ RUBY_PLATFORM
  "script -q -c'#{shell_command}' -e #{log_file} > /dev/null"
end

def redirect_to(shell_command, log_file)
  script_command = script_command(shell_command, log_file)
  log_file_path = log_file.relative_path_from(STASH_ROOT)
  puts "#{working_path}: #{yellow(shell_command)} > #{log_file_path}"
  system(script_command)
rescue => ex
  $stderr.puts("#{shell_command} failed: #{ex}")
  false
end

def dir_for(project)
  STASH_ROOT + project
end

def in_project(project)
  Dir.chdir(dir_for(project)) { yield }
end

# ########################################
# Build steps

def bundle(project)
  Bundler.with_clean_env do
    in_project(project) do
      run_task("bundle-#{project}", 'bundle install')
    end
  end
rescue => e
  $stderr.puts(e)
  return false
end

def prepare(project)
  in_project(project) do
    travis_prep_sh = "./#{TRAVIS_PREP_SH}"
    return true unless File.exist?(travis_prep_sh)
    run_task("prepare-#{project}", travis_prep_sh)
  end
rescue => e
  $stderr.puts(e)
  return false
end

def build(project)
  in_project(project) do
    run_task("build-#{project}", 'bundle exec rake')
  end
rescue => e
  $stderr.puts(e)
  return false
end

def bundle_all
  PROJECTS.each do |p|
    bundle_ok = bundle(p)
    $stderr.puts(red("#{p} bundle failed")) unless bundle_ok
    exit(1) unless bundle_ok
  end
  true
end

def build_all
  PROJECTS.each do |p|
    prep_ok = prepare(p)
    $stderr.puts(red("#{p} prep failed")) unless prep_ok
    next unless prep_ok

    build_ok = build(p)
    (build_ok ? successful_builds : failed_builds) << p
    $stderr.puts(red("#{p} build failed")) unless build_ok
  end
end

# ########################################
# Build commands

bundle_all

build_all

$stderr.puts("The following projects built successfully: #{successful_builds.map(&method(:green)).join(', ')}") unless successful_builds.empty?
exit(0) if failed_builds.empty?

$stderr.puts("The following projects failed to build: #{failed_builds.map(&method(:red)).join(', ')}")
exit(1)
