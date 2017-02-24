require 'stash/repo/file_builder'

module Stash
  module Merritt
    class SubmissionPackage
      class MerrittEmbargoBuilder < Stash::Repo::FileBuilder
        attr_reader :embargo_end_date

        def initialize(embargo_end_date:)
          super(file_name: 'mrt-embargo.txt')
          @embargo_end_date = embargo_end_date
        end

        def contents
          return unless embargo_end_date
          embargo_end_date.iso8601
        end
      end
    end
  end
end
