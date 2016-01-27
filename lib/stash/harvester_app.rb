require_relative 'harvester'

module Stash

  # Workaround to allow HarvesterApp to access Harvester classes with unqualified names.
  module Harvester
    alias old_included included if method_defined? :included
    def self.included(base)
      old_included(base) if method_defined? :old_included
      constants.each { |c| base.const_set(c, const_get("#{self}::#{c}")) }
    end
  end

  # Harvester application, as opposed to Harvester library
  module HarvesterApp
    include Harvester

    Dir.glob(File.expand_path('../harvester_app/*.rb', __FILE__), &method(:require))
  end
end
