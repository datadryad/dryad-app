require_relative 'index_status'

module Stash
  module Indexer
    class IndexResult

      attr_reader :record
      attr_reader :status
      attr_reader :errors

      # Creates a new `IndexResult`
      # @param record [HarvestedRecord] the record being indexed
      # @param status [IndexStatus] `IndexStatus::COMPLETED` if successful,
      #   `IndexStatus::FAILED` otherwise.
      # @param errors [Array<Exception>] errors for this record, if any.
      def initialize(record:, status: IndexStatus::COMPLETED, errors: [])
        @record = record
        @status = status
        @errors = errors
      end

      # @return [boolean] `true` if `status` is `IndexStatus::COMPLETED` and
      #   there are no errors; `false` otherwise
      def success?
        @errors.empty? && @status == IndexStatus::COMPLETED
      end

      # @return [boolean] `true` if `success?` returns `false`, `false` otherwise
      def failure?
        !success?
      end

      # @return [boolean] `true` if this result has errors, false otherwise
      def errors?
        !@errors.empty?
      end

      # TODO: add and use factory methods for success and failure
    end
  end
end
