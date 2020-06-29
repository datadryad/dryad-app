require_relative '../../../../stash_datacite/app/models/stash_datacite/affiliation'

module StashEngine
  class Author < ActiveRecord::Base

    include StashEngine::Concerns::ResourceUpdated

    belongs_to :resource, class_name: 'StashEngine::Resource'

    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.freeze

    validates :author_email, format: EMAIL_REGEX, allow_blank: true

    before_save :strip_whitespace

    scope :names_filled, -> { where("TRIM(IFNULL(author_first_name,'')) <> '' AND TRIM(IFNULL(author_last_name,'')) <> ''") }

    amoeba do
      enable
    end

    def self.primary(resource_id)
      where(resource_id: resource_id).where.not(author_email: nil).order(:id)&.first
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def ==(other)
      return false unless other.present?
      return true if author_orcid.present? && other.author_orcid == author_orcid
      return true if author_email.present? && other.author_email == author_email

      other.author_last_name&.strip&.downcase == author_last_name&.strip&.downcase &&
        other.author_first_name&.strip&.downcase == author_first_name&.strip&.downcase
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def author_full_name
      [author_last_name, author_first_name].reject(&:blank?).join(', ')
    end

    def author_standard_name
      "#{author_first_name} #{author_last_name}".strip
    end

    def author_html_email_string
      return if author_email.blank?

      "<a href=\"mailto:#{CGI.escapeHTML(author_email.strip)}\">#{CGI.escapeHTML(author_standard_name.strip)}</a>"
    end

    # NOTE: this ONLY works b/c we assume that only the resource-owning
    # user can set their own ORCiD
    def init_user_orcid
      return unless author_orcid
      return unless (user = resource&.user)
      return if user&.orcid

      user.orcid = author_orcid
      user.save
    end
    after_save :init_user_orcid

    private

    def strip_whitespace
      self.author_first_name = author_first_name.strip if author_first_name
      self.author_last_name = author_last_name.strip if author_last_name
      self.author_email = author_email.strip if author_email
      self.author_orcid = nil if author_orcid.blank?
    end
  end
end
