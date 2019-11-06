require 'spec_helper'

module Stash
  module Merritt
    describe Repository do
      describe :create_submission_job do
        it 'creates a submission job' do
          url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
          repo = Repository.new(url_helpers: url_helpers, threads: 1)
          resource_id = 17
          job = repo.create_submission_job(resource_id: resource_id)
          expect(job).to be_a(SubmissionJob)
          expect(job.resource_id).to eq(resource_id)
          expect(job.url_helpers).to be(url_helpers)
        end
      end
    end
  end
end
