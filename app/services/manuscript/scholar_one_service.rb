module Manuscript
  class ScholarOneService
    attr_reader :metadata

    def initialize(metadata, identifier = nil)
      @metadata = metadata
      @identifier = identifier
    end

    def create
      return false if metadata.blank?

      status = metadata.dig(:submissionStatus, :documentStatusName).downcase
      return unless %w[submitted accepted rejected].include?(status)
      return if journal.blank?

      manu = StashEngine::Manuscript.find_or_initialize_by(manuscript_number: manuscript_number)
      manu.update(
        journal: journal,
        identifier: identifier,
        status: status,
        metadata: metadata
      )
      return if manu&.id.blank?

      StashEngine::Manuscript.update_existing_dataset_status(manu)
      manu
    end

    private

    def journal
      return @journal if @journal

      @journal = StashEngine::Journal.find_by_issn(metadata[:journalDigitalIssn]) if metadata[:journalDigitalIssn]
      @journal ||= StashEngine::Journal.find_by_title(metadata[:journalName]) if metadata[:journalName]
      @journal
    end

    def identifier
      # TODO: metadata[:doi] may not exist or may be a different key
      @identifier || StashEngine::Identifier.find_by_identifier(metadata[:doi])

      return @identifier if @identifier

      resource = StashEngine::Resource.latest_per_dataset.joins(:resource_publication)
        .where(resource_publication: { manuscript_number: manuscript_number }).last
      ident = resource&.identifier
      @identifier = ident if ident&.journal == @journal
    end

    def manuscript_number
      metadata[:submissionId]
    end

    def status
      metadata.dig(:submissionStatus, :documentStatusName).downcase
    end
  end
end
