module Mocks

  module CurationActivity
    def neuter_curation_callbacks!
      # These callbacks cause constant grief when you're just trying to set up curation states in order to
      # do things like test dataset visibility.  Mostly we don't want these running in tests unless we're testing that
      # callback explicitly.
      mock_invoicer = double('inv')
      allow(mock_invoicer).to receive(:check_new_overages).and_return(true)
      allow(mock_invoicer).to receive(:charge_user_via_invoice).and_return(true)
      allow(Stash::Payments::Invoicer).to receive(:new).and_return(mock_invoicer)
      neuter_emails!
      ignore_zenodo!
    end

    def neuter_emails!
      allow_any_instance_of(CurationService).to receive(:email_status_change_notices).and_return(true)
      allow_any_instance_of(CurationService).to receive(:email_orcid_invitations).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:journal_published_notice).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation).and_return(true)
    end

    def ignore_zenodo!
      allow_any_instance_of(CurationService).to receive(:copy_to_zenodo).and_return(true)
      allow_any_instance_of(StashEngine::Resource).to receive(:send_software_to_zenodo).and_return(true)
      allow_any_instance_of(StashEngine::Resource).to receive(:send_supp_to_zenodo).and_return(true)
    end
  end
end
