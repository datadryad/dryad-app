require 'stash/harvester'
require 'stash/indexer'
require 'forwardable'

module Stash

  # Workaround to allow HarvesterApp to access Harvester classes and methods with unqualified names.
  module Harvester
    alias old_included included if method_defined? :included
    def self.included(base)
      old_included(base) if method_defined? :old_included
      constants.each { |c| base.const_set(c, const_get("#{self}::#{c}")) }
      base.extend SingleForwardable
      methods(false).each do |m|
        base.def_delegator self, m
      end
    end
  end

  # Harvester application, as opposed to Harvester library
  module HarvesterApp
    include Harvester

    Dir.glob(File.expand_path('harvester_app/*.rb', __dir__)).sort.each(&method(:require))
  end
end
