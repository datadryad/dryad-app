# frozen_string_literal: true

class AddPeerReviewCustomTextForAcs < ActiveRecord::Migration[7.0]
  def up
    return if Rails.env.production?

    StashEngine::JournalOrganization.where(name: 'American Chemical Society')
                                    .first
                                    .journals_sponsored_deep
                                    .update_all(
                                      peer_review_custom_text: '<b>Special Note to ACS Chemistry Databank users:</b> The Reviewer URL will be provided to the journal office on your behalf. ACS Publications will review the dataset and may request revisions during the peer review process.Dryad curation occurs after manuscript acceptance. Turnaround times for the data reviewers can vary.  You can check the status and edit your data on the Chemistry Databank "<a href="https://chemdatabank-test.acs.org/dashboard/datasets/">My Datasets</a>" page up until the point Dryad publishes the dataset. If you have any questions, please reach out to <a href="https://acs.service-now.com/acs">ACS Publications Support</a>. '
                                    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
