module StashEngine
  class Manuscript < ApplicationRecord
    self.table_name = 'stash_engine_manuscripts'
    belongs_to :journal
    belongs_to :identifier, optional: true
    serialize :metadata

    def accepted?
      accepted_statuses = %w[accepted published]
      accepted_statuses.include?(status)
    end

    def rejected?
      rejected_statuses = ['rejected', 'transferred', 'rejected w/o review']
      rejected_statuses.include?(status)
    end

    # Create a new Manuscript from the content of an email message
    def self.from_message_content(content:)
      result = OpenStruct.new(success?: false, error: 'No content')
      return result unless content

      parser = EmailParser.new(content: content)
      parsing_error = check_parsing_errors(parser)

      if parsing_error
        result[:error] = parsing_error
      else
        manu = Manuscript.create(journal: parser.journal,
                                 identifier: parser.identifier,
                                 manuscript_number: parser.manuscript_number,
                                 status: parser.article_status,
                                 metadata: parser.metadata_hash)

        if manu.present? && manu.id.present?
          update_existing_dataset_status(manu)
          result.delete_field('error')
          result[:success?] = true
          result[:payload] = manu
        end
      end

      result
    end

    def self.update_existing_dataset_status(manuscript)
      return unless manuscript.identifier

      target_status = nil
      target_note = "setting manuscript status based on notification from journal #{manuscript.journal&.title} " \
                    "-- manuscript #{manuscript.manuscript_number}, status #{manuscript.status}"
      if manuscript.accepted?
        target_status = 'submitted'
      elsif manuscript.rejected?
        target_status = 'withdrawn'
      end

      resource = manuscript.identifier.latest_resource

      # if the status is being updated based on notification from a journal, DON'T go backwards in workflow,
      # that is, don't change a status other than submitted or peer_review
      unless %w[submitted peer_review].include?(resource.current_curation_status)
        target_note = "received notification from journal module that the associated manuscript is #{manuscript.status}, " \
                      "but the dataset is #{resource.current_curation_status}, so it will retain that status"
        target_status = resource.current_curation_status
      end

      return unless target_status

      # once we receive a notification from the journal, we know that the manuscript is no longer in
      # review, so remove the hold_for_peer_review setting
      resource.update(hold_for_peer_review: false, peer_review_end_date: nil)

      StashEngine::CurationActivity.create(resource: resource,
                                           status: target_status,
                                           user_id: 0,  # system user
                                           note: target_note)
    end

    def self.check_parsing_errors(parser)
      return 'Unable to locate Journal -- either through Journal Code or an ISSN' unless parser.journal
      return 'Article Status not found' unless parser.article_status
      unless parser.manuscript_number || parser.identifier
        return 'Unable to identify manuscript -- either through MS Reference Number or Dryad Data DOI'
      end

      hash = parser.metadata_hash
      return 'Unable to create metadata hash' unless hash.present?
      return 'Unable to parse MS Authors' unless hash['ms authors'].present?
      return 'Unable to locate MS Title' unless hash['ms title'].present?

      nil
    end
  end
end
