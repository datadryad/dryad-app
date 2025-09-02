module Mocks
  module SubmissionJob

    def mint_id
      "doi:#{Faker::Pid.doi}"
    end

    def mock_submission_job!
      allow_any_instance_of(Stash::Repo::Repository).to receive(:download_uri_for).and_return(mint_id)
      allow_any_instance_of(Stash::Repo::Repository).to receive(:update_uri_for).and_return(mint_id)
      allow_any_instance_of(Stash::Repo::SubmissionJob).to receive(:do_submit!) do
        sleep 3
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
      end
    end
  end
end
