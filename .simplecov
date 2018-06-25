require 'simplecov-console'

# Up one level to include stash
COVERAGE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# Hack for SimpleCov #5 https://github.com/chetan/simplecov-console/issues/5
SimpleCov::Formatter::Console::ROOT = COVERAGE_ROOT
Module::ROOT = COVERAGE_ROOT

# Filter out third-party code
class VendorFilter < SimpleCov::Filter
  def matches?(source_file)
    path = source_file.filename
    path =~ %r{vendor/bundle/ruby} ||
      path =~ %r{rvm/gems/ruby} ||
      path =~ %r{rvm/rubies}
  end
end

SimpleCov.configure do
  filters.clear
  add_filter '/spec/'
  add_filter VendorFilter.new(COVERAGE_ROOT)
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
end
