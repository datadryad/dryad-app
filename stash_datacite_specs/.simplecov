require 'simplecov-console'

class StashEngineFilter < SimpleCov::Filter
  def matches?(source_file)
    stash_datacite_path = filter_argument
    path = source_file.filename
    return true if path =~ %r{db/migrate}
    return true if path =~ %r{vendor/bundle/ruby}
    return false if path =~ /^#{stash_datacite_path}/
    return false if path =~ /^#{SimpleCov.root}/
    true
  end
end

# Hack for SimpleCov #5 https://github.com/chetan/simplecov-console/issues/5
Module::ROOT = Dir.pwd
SimpleCov::Formatter::Console::ROOT = Dir.pwd

# SimpleCov.command_name 'spec:lib'
SimpleCov.minimum_coverage 100

SimpleCov.start do
  filters.clear
  add_filter '/spec/'
  stash_datacite_path = Gem::Specification.find_by_name('stash_datacite').gem_dir
  add_filter StashEngineFilter.new(stash_datacite_path)
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
  ]
end
