#!/usr/bin/env ruby

require 'bundler'
require 'pathname'
require 'time'

PROJECTS = %w(
  stash-wrapper
  stash-harvester
  stash-sword
  stash-merritt
  stash_engine
  stash_engine_specs
  stash_discovery
  stash_datacite
  stash_datacite_specs
)

def exec_command(command, log_file)
  # preserve ANSI colors, see https://stackoverflow.com/a/27399198/27358
  system("script -q #{log_file} #{command} > /dev/null")
end

root = Pathname.new(__dir__)

def bundle(project_dir, bundle_out)
  puts "bundling #{project_dir}"
  Dir.chdir(project_dir) do
    Bundler.with_clean_env do
      bundle_ok = exec_command('bundle install', bundle_out)
      $stderr.puts("bundle failed: #{project_dir}") unless bundle_ok
      system("cat #{bundle_out}") unless bundle_ok
      return bundle_ok
    end
  end
end

def prepare(project_dir, prep_out)
  prep_script = project_dir + 'travis-prep.sh'
  return true unless prep_script.exist?

  puts "preparing: #{prep_script}"
  unless FileTest.executable?(prep_script.to_s)
    $stderr.puts("prepare failed: #{prep_script} is not executable")
    return false
  end

  prep_ok = exec_command(prep_script, prep_out)
  $stderr.puts("prepare failed: #{prep_script}") unless prep_ok
  system("cat #{prep_out}") unless prep_ok
  prep_ok
end

def build(project_dir, build_out)
  Dir.chdir(project_dir) do
    begin
      prep_out = build_out.sub('-build', '-prep')
      prep_ok = prepare(project_dir, prep_out)
      return false unless prep_ok

      puts "building #{project_dir}"
      Bundler.with_clean_env do
        build_ok = exec_command('bundle exec rake', build_out)
        $stderr.puts("build failed: #{project_dir}") unless build_ok
        system("cat #{build_out}") unless build_ok
        return build_ok
      end
    rescue => e
      $stderr.puts(e)
      return false
    end
  end
end

tmpdir = File.absolute_path("builds/#{Time.now.utc.iso8601}")
FileUtils.mkdir_p(tmpdir)
puts "logging build output to #{tmpdir}"
tmp_path = Pathname.new(tmpdir)
PROJECTS.each do |p|
  bundle_out = tmp_path + ("#{p}-bundle.out")
  bundle_ok = bundle(root + p, bundle_out)
  exit(1) unless bundle_ok
end

build_succeeded = []
build_failed = []
PROJECTS.each do |p|
  build_out = tmp_path + ("#{p}-build.out")
  build_ok = build(root + p, build_out)
  build_succeeded << p if build_ok
  build_failed << p unless build_ok
end

unless build_succeeded.empty?
  $stderr.puts("The following projects built successfully: #{build_succeeded.join(', ')}")
end

unless build_failed.empty?
  $stderr.puts("The following projects failed to build: #{build_failed.join(', ')}")
  exit(1)
end
