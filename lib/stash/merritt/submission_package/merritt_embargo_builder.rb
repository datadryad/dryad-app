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
          end_date_str = (embargo_end_date && embargo_end_date.iso8601)
          "embargoEndDate:#{end_date_str || 'none'}"
        end
      end
    end
  end
end
