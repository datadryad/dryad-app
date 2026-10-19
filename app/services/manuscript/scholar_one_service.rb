module Manuscript
  class ScholarOneService
    attr_reader :metadata

    def initialize(metadata, identifier = nil)
      @metadata = metadata
      @identifier = identifier
    end

    def process
      return false if metadata.blank?

      status = metadata.dig(:submissionStatus, :documentStatusName).downcase
      return unless %w[submitted accepted rejected].include?(status)
      return if journal.blank?

      send_email_notification
      manu = StashEngine::Manuscript.find_or_initialize_by(manuscript_number: manuscript_number)
      manu.update(
        journal: journal,
        identifier: identifier,
        status: status,
        metadata: metadata
      )
      return if manu&.id.blank?

      journal&.update(integrated_at: Time.current)
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
      return @identifier if @identifier

      resource = StashEngine::Resource.latest_per_dataset.joins(:resource_publication)
        .where(resource_publication: { manuscript_number: manuscript_number }).last
      ident = resource&.identifier
      @identifier = ident if ident&.journal == @journal
      @identifier
    end

    def manuscript_number
      metadata[:submissionId]
    end

    def status
      metadata.dig(:submissionStatus, :documentStatusName).downcase
    end

    def send_email_notification
      return unless dryad_question_answered_yes
      return unless status == 'submitted'
      return if identifier.present?

      authors_metadata = Integrations::ScholarOne.new(journal).authors_metadata(manuscript_number)
      return unless authors_metadata.present?

      authors_metadata = [authors_metadata] unless authors_metadata.is_a?(Array)
      StashApi::ApiMailer.send_scholar_one_submit_request(journal, metadata, authors_metadata.first).deliver_now
    end

    def dryad_question_answered_yes
      # dryad answer
      questions = metadata['submissionCustomQuestions']
      questions = [questions] unless questions.is_a?(Array)
      questions.each do |question|
        return true if question['questionName'].downcase == 'dryad' && question.dig('submissionCustomAnswer', 'answerName').downcase == 'yes'
      end

      false
    end
  end
end
