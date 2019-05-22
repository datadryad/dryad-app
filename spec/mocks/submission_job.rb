module Mocks
  module SubmissionJob

    def mint_id
      "doi:#{Faker::Pid.doi}"
    end

    def mock_submission_job!
      allow_any_instance_of(Stash::Merritt::Repository).to receive(:download_uri_for).and_return(mint_id)
      allow_any_instance_of(Stash::Merritt::Repository).to receive(:update_uri_for).and_return(mint_id)
      Stash::Merritt::SubmissionJob.prepend(Mocks::SubmissionJob::MonkeyPatch) # a way to override this method
    end

    module MonkeyPatch
      def do_submit!
        sleep 30 # to simulate submission happening, this should be in background thread, so enjoy!
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
      end
    end
  end
end
