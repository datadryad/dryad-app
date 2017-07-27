require 'spec_helper'

module Stash
  module Repo
    describe SubmissionResult do
      describe '#success' do
        it 'returns a successful result' do
          resource_id = 17
          request_desc = 'elvis'
          message = 'presley'
          result = SubmissionResult.success(resource_id: resource_id, request_desc: request_desc, message: message)
          expect(result.resource_id).to eq(resource_id)
          expect(result.request_desc).to eq(request_desc)
          expect(result.message).to eq(message)
          expect(result.error).to be_nil
        end
      end
      describe '#failure' do
        it 'returns a failed result' do
          resource_id = 17
          request_desc = 'elvis'
          error = ActiveRecord::ConnectionTimeoutError.new('oops')
          result = SubmissionResult.failure(resource_id: resource_id, request_desc: request_desc, error: error)
          expect(result.resource_id).to eq(resource_id)
          expect(result.request_desc).to eq(request_desc)
          expect(result.message).to be_nil
          expect(result.error).to eq(error)
        end
      end
    end
  end
end
