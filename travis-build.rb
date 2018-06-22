#!/usr/bin/env ruby

require 'bundler'
require 'colorize'
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
  stash_discovery
  stash_datacite
  stash_api
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

def warn(msg)
  $stderr.puts(msg.to_s.red)
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

def run_folded(shell_command, task_name)
  travis_fold(task_name) do
    puts "#{working_path}: #{shell_command.yellow}"
    return system(shell_command)
  end
end

def run_task(task_name, shell_command)
  return run_folded(shell_command, task_name) if IN_TRAVIS

  log_file = tmp_path + "#{task_name}.out"
  build_ok = redirect_to(shell_command, log_file)
  return build_ok if build_ok

  warn("#{shell_command} failed")
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
  puts "#{working_path}: #{shell_command.yellow} > #{log_file_path}"
  system(script_command)
rescue => ex
  warn("#{shell_command} failed: #{ex}")
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
  warn(e)
  return false
end

def prepare(project)
  in_project(project) do
    travis_prep_sh = "./#{TRAVIS_PREP_SH}"
    return true unless File.exist?(travis_prep_sh)
    run_task("prepare-#{project}", travis_prep_sh)
  end
rescue => e
  warn(e)
  return false
end

def build(project)
  in_project(project) do
    run_task("build-#{project}", 'bundle exec rake')
  end
rescue => e
  warn(e)
  return false
end

def bundle_all
  PROJECTS.each do |p|
    bundle_ok = bundle(p)
    warn("#{p} bundle failed") unless bundle_ok
    exit(1) unless bundle_ok
  end
  true
end

def build_all
  PROJECTS.each do |p|
    prep_ok = prepare(p)
    warn("#{p} prep failed") unless prep_ok
    next unless prep_ok

    build_ok = build(p)
    (build_ok ? successful_builds : failed_builds) << p
    warn("#{p} build failed") unless build_ok
  end
end

# ########################################
# Options

require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: travis-build.rb [options]"
  opts.on('-h', '--help', 'Show help and exit') do
    puts opts
    exit(0)
  end
  opts.on('-b', '--bundle-only', 'Bundle all subprojects but do not build') do
    puts 'Bundling only'
    options[:bundle_only] = true
  end
end.parse!

# ########################################
# Build commands

# ####################
# Bundle all projects

bundle_all

if options[:bundle_only]
  exit(0)
end

# ####################
# Build all projects

build_all

# ####################
# Report results

unless successful_builds.empty?
  puts("The following projects built successfully: #{successful_builds.join(', ').green}")
end

unless failed_builds.empty?
  warn("The following projects failed to build: #{failed_builds.join(', ').red}")
  exit(1)
end

