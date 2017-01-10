require 'stash/repo'

module Stash
  module Merritt
    class SwordTask < Stash::Repo::Task
      attr_reader :sword_params
      def initialize(sword_params:)
        @sword_params = sword_params
      end

      # @return [Package] the package
      def exec(package)
        package
      end
    end
  end
end
