#!/usr/bin/env ruby

require 'bundler'
require 'pathname'

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

root = Pathname.new(__dir__)

def bundle(project_dir)
  puts "bundling #{project_dir}"
  Dir.chdir(project_dir) do
    Bundler.with_clean_env do
      bundle_ok = system('bundle install')
      $stderr.puts("bundle failed: #{project_dir}") unless bundle_ok
      return bundle_ok
    end
  end
end

def prepare(project_dir)
  prep_script = project_dir + 'travis-prep.sh'
  return true unless prep_script.exist?

  puts "preparing: #{prep_script}"
  unless FileTest.executable?(prep_script.to_s)
    $stderr.puts("prepare failed: #{prep_script} is not executable")
    return false
  end

  prep_ok = system(prep_script.to_s, err: :out)
  $stderr.puts("prepare failed: #{prep_script}") unless prep_ok
  prep_ok
end

def build(project_dir)
  puts "building #{project_dir}"
  Dir.chdir(project_dir) do
    begin
      prep_ok = prepare(project_dir)
      return false unless prep_ok

      Bundler.with_clean_env do
        build_ok = system('bundle exec rake')
        $stderr.puts("build failed: #{project_dir}") unless build_ok
        return build_ok
      end
    rescue => e
      $stderr.puts(e)
      return false
    end
  end
end


PROJECTS.each do |p|
  bundle_ok = bundle(root + p)
  exit(1) unless bundle_ok
end

build_failures = []
PROJECTS.each do |p|
  build_ok = build(root + p)
  build_failures << p unless build_ok
end

unless build_failures.empty?
  $stderr.puts("The following projects failed to build: #{build_failures.join(', ')}")
  exit(1)
end
