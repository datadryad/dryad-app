module Manuscript
  class ScholarOneService
    attr_reader :metadata

    def initialize(metadata)
      @metadata = metadata
    end

    def create
      status = metadata.dig(:submissionStatus, :documentStatusName).downcase
      return unless %w[submitted accepted].include?(status)
      return if journal.blank?

      manu = StashEngine::Manuscript.create!(
        journal: journal,
        identifier: identifier,
        manuscript_number: manuscript_number,
        status: status,
        metadata: metadata
      )
      return if manu&.id.blank?

      StashEngine::Manuscript.update_existing_dataset_status(manu)
      journal&.update(integrated_at: manu.created_at)
    end

    private

    def journal
      return @journal if @journal

      @journal = StashEngine::Journal.find_by_issn(metadata[:journalDigitalIssn]) if metadata[:journalDigitalIssn]
      @journal ||= StashEngine::Journal.find_by_title(metadata[:journalName]) if metadata[:journalName]
      @journal
    end

    def identifier
      StashEngine::Identifier.find_by_identifier metadata[:doi]
    end

    def manuscript_number
      metadata[:submissionId]
    end

    def status
      metadata.dig(:submissionStatus, :documentStatusName).downcase
    end
  end
end
