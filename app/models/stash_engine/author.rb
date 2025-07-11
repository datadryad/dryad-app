# == Schema Information
#
# Table name: stash_engine_authors
#
#  id                 :integer          not null, primary key
#  author_email       :string(191)
#  author_first_name  :string(191)
#  author_last_name   :string(191)
#  author_orcid       :string(191)
#  author_order       :integer
#  author_org_name    :string(255)
#  corresp            :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  resource_id        :integer
#  stripe_customer_id :text(65535)
#
# Indexes
#
#  index_stash_engine_authors_on_author_orcid  (author_orcid)
#  index_stash_engine_authors_on_resource_id   (resource_id)
#
module StashEngine
  class Author < ApplicationRecord
    self.table_name = 'stash_engine_authors'
    has_paper_trail

    belongs_to :resource, class_name: 'StashEngine::Resource'
    has_many :affiliation_authors, class_name: 'StashDatacite::AffiliationAuthor', dependent: :destroy
    has_many :affiliations, class_name: 'StashDatacite::Affiliation', through: :affiliation_authors
    has_one :edit_code, class_name: 'StashEngine::EditCode', dependent: :destroy

    # I believe the default to ordering by author oder is fin and it falls back to the ID order (order of creation) as secondary
    default_scope { order(author_order: :asc, id: :asc) }

    accepts_nested_attributes_for :affiliations

    validates :author_email, format: EMAIL_REGEX, allow_blank: true

    before_save :strip_whitespace

    scope :names_filled, -> { where("TRIM(IFNULL(author_first_name,'')) <> '' AND TRIM(IFNULL(author_last_name,'')) <> ''") }
    scope :with_orcid, -> { where.not(author_orcid: [nil, '']) }

    amoeba do
      clone :affiliation_authors
    end

    def ==(other)
      return false unless other.present?
      return true if author_orcid.present? && other.author_orcid == author_orcid
      return true if author_email.present? && other.author_email == author_email

      other.author_last_name&.strip&.downcase == author_last_name&.strip&.downcase &&
        other.author_first_name&.strip&.downcase == author_first_name&.strip&.downcase
    end

    def affiliation
      affiliations.first
    end

    def affiliation=(affil)
      return unless affil.is_a?(StashDatacite::Affiliation)

      affiliations << affil
    end

    def author_full_name
      return author_org_name unless author_org_name.blank?

      [author_last_name, author_first_name].reject(&:blank?).join(', ')
    end

    def author_standard_name
      return author_org_name unless author_org_name.blank?

      "#{author_first_name} #{author_last_name}".strip
    end

    def author_html_email_string
      return if author_email.blank?

      "<a href=\"mailto:#{CGI.escapeHTML(author_email.strip)}\">#{CGI.escapeHTML(author_standard_name.strip)}</a>"
    end

    def user
      return nil if author_orcid.blank? && author_email.blank?

      user = StashEngine::User.where(orcid: author_orcid)&.first if author_orcid.present?
      user ||= StashEngine::User.where(email: author_email)&.first if author_email.present?
      user
    end

    # NOTE: this ONLY works b/c we assume that only the resource-owning
    # user can set their own ORCiD
    def init_user_orcid
      return unless author_orcid
      return unless (user = resource&.submitter)
      return if user&.orcid

      user.orcid = author_orcid
      user.save
    end
    after_save :init_user_orcid

    def orcid_invite_path
      return nil if author_email.blank?

      orcid_invite = StashEngine::OrcidInvitation.where(email: author_email, identifier_id: resource.identifier_id)&.first
      # Ensure an invite exists -- it may not for a legacy dataset that never received invites,
      # or if the author_email has changed since the original creation.
      orcid_invite ||= StashEngine::OrcidInvitation.create(
        email: author_email,
        identifier_id: resource.identifier_id,
        first_name: author_first_name,
        last_name: author_last_name,
        secret: SecureRandom.urlsafe_base64,
        invited_at: Time.new.utc
      )

      path = Rails.application.routes.url_helpers.show_path(orcid_invite.identifier.to_s, invitation: orcid_invite.secret)
      orcid_invite.landing(path)
    end

    def as_api_json
      {
        firstName: author_first_name,
        lastName: author_last_name,
        email: author_email,
        affiliation: affiliation&.smart_name,
        affiliationROR: affiliation&.ror_id,
        affiliations: affiliations.map(&:as_api_json),
        orcid: author_orcid,
        order: author_order
      }
    end

    private

    def strip_whitespace
      self.author_first_name = author_first_name.strip if author_first_name
      self.author_last_name = author_last_name.strip if author_last_name
      self.author_email = author_email.strip if author_email
      self.author_orcid = nil if author_orcid.blank?
    end
  end
end
