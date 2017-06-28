require 'simplecov-console'

# Up one level to include stash local dependencies
WORKDIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# Hack for SimpleCov #5 https://github.com/chetan/simplecov-console/issues/5
Module::ROOT = WORKDIR
SimpleCov::Formatter::Console::ROOT = WORKDIR

# Filter out third-party code
class VendorFilter < SimpleCov::Filter
  def matches?(source_file)
    path = source_file.filename
    path =~ %r{vendor/bundle/ruby} ||
      path =~ %r{rvm/gems/ruby} ||
      path =~ %r{rvm/rubies}
  end
end

SimpleCov.start do
  filters.clear
  add_filter '/spec/'
  add_filter VendorFilter.new(WORKDIR)
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
  ]
end
