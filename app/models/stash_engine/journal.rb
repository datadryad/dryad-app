# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  allow_review_workflow   :boolean          default(TRUE)
#  api_contacts            :text(65535)
#  default_to_ppr          :boolean          default(FALSE)
#  description             :text(65535)
#  integrated_at           :datetime
#  journal_code            :string(191)
#  manuscript_number_regex :string(191)
#  notify_contacts         :text(65535)
#  peer_review_custom_text :text(65535)
#  preprint_server         :boolean          default(FALSE)
#  review_contacts         :text(65535)
#  title                   :string(191)
#  website                 :string(191)
#  created_at              :datetime
#  updated_at              :datetime
#  sponsor_id              :integer
#  stripe_customer_id      :string(191)
#
# Indexes
#
#  index_stash_engine_journals_on_title  (title)
#
module StashEngine
  class Journal < ApplicationRecord
    self.table_name = 'stash_engine_journals'
    PAYMENT_PLANS = %w[SUBSCRIPTION PREPAID DEFERRED TIERED 2025].freeze

    validates :title, presence: true
    validates :journal_code, uniqueness: { allow_blank: true, case_sensitive: false }
    validate :email_array

    has_many :issns, -> { order(created_at: :asc) }, class_name: 'StashEngine::JournalIssn', inverse_of: :journal, dependent: :destroy
    has_many :alternate_titles, class_name: 'StashEngine::JournalTitle', dependent: :destroy
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object, dependent: :destroy
    has_many :users, through: :roles
    has_many :manuscripts, -> { order(created_at: :desc) }, class_name: 'StashEngine::Manuscript'
    has_one :flag, class_name: 'StashEngine::Flag', as: :flaggable, dependent: :destroy
    belongs_to :sponsor, class_name: 'StashEngine::JournalOrganization', optional: true
    has_one :payment_configuration, as: :partner, dependent: :destroy
    has_many :payment_logs, class_name: 'SponsoredPaymentLog', as: :payer

    validates_associated :issns
    accepts_nested_attributes_for :flag, allow_destroy: true
    accepts_nested_attributes_for(*%i[issns alternate_titles])
    accepts_nested_attributes_for :payment_configuration, allow_destroy: true, reject_if: :all_blank

    scope :servers, -> { where(preprint_server: true) }

    def will_pay?
      PAYMENT_PLANS.include?(payment_sponsor&.payment_configuration&.payment_plan)
    end

    def api_journal?
      return false unless integrated_at >= 2.years.ago
      return false if manuscripts.first&.created_at == integrated_at

      true
    end

    def top_level_org
      return nil unless sponsor

      o = sponsor
      o = o.parent_org while o.parent_org
      o
    end

    # Return the single ISSN that is representative of this journal,
    # even if the journal contains multiple ISSNs
    def single_issn
      issn_ids.first
    end

    # Return an array of ISSNs, even if the journal contains a single ISSN
    def issn_array
      issn_ids
    end

    def notify_contacts
      JSON.parse(super) unless super.nil?
    end

    def review_contacts
      JSON.parse(super) unless super.nil?
    end

    def api_contacts
      JSON.parse(super) unless super.nil?
    end

    def email_array
      notify_contacts&.each do |email|
        errors.add(:notify_contacts, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
      end
      review_contacts&.each do |email|
        errors.add(:review_contacts, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
      end
      api_contacts&.each do |email|
        errors.add(:review_contacts, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
      end
    end

    def self.find_by_title(title)
      return unless title.present?

      title = title.chop if title&.end_with?('*')
      journal = StashEngine::Journal.where(title: title).first

      unless journal.present?
        alt = StashEngine::JournalTitle.where(title: title).first
        journal = alt.journal if alt.present?
      end
      journal
    end

    def self.find_by_issn(issn)
      return nil if issn.blank? || issn.size < 9

      StashEngine::JournalIssn.find_by(id: issn)&.journal
    end

    def self.api_journals
      journals = StashEngine::Journal.where(integrated_at: 2.years.ago..)
      journals.reject { |j| j.manuscripts.first&.created_at == j.integrated_at }
    end

    def self.with_sponsorship
      StashEngine::Journal.with_recursive(
        top_sponsor: [
          StashEngine::JournalOrganization.all.select(:id, { id: :root_org_id }, :parent_org_id),
          StashEngine::JournalOrganization.joins('JOIN top_sponsor ON stash_engine_journal_organizations.id = top_sponsor.parent_org_id').select(
            'top_sponsor.id', { id: :root_org_id }, :parent_org_id
          )
        ]
      )
        .joins('LEFT OUTER JOIN top_sponsor on stash_engine_journals.sponsor_id = top_sponsor.id')
        .joins("LEFT OUTER JOIN payment_configurations pc
          ON pc.partner_type = 'StashEngine::JournalOrganization' AND pc.partner_id = top_sponsor.root_org_id")
        .select({ stash_engine_journals: ['*'] }, { top_sponsor: [:root_org_id] }, { pc: [:payment_plan] })
        .where('top_sponsor.parent_org_id': nil)
    end

    # Replace an uncontrolled journal name (typically containing '*')
    # with a controlled journal reference, using an id
    def self.replace_uncontrolled_journal(old_name:, new_journal:)
      j = new_journal
      data = StashEngine::InternalDatum.where(value: old_name)
      idents = data.map(&:identifier_id)
      idents.each do |ident|
        puts "  converting journal for identifier #{ident}"
        update_journal_for_identifier(new_title: j.title, new_issn: j.single_issn, identifier_id: ident)
      end
      pubs = StashEngine::ResourcePublication.where(publication_name: old_name, publication_issn: [nil, ''])
      pubs.find_each do |pub|
        puts "  converting journal for resource #{pub.resource_id}"
        update_journal_for_resource(new_title: j.title, new_issn: j.single_issn, resource_id: pub.resource_id)
      end
    end

    # Update the journal settings for a single Identifier
    def self.update_journal_for_identifier(identifier_id:, new_title:, new_issn:)
      i = StashEngine::Identifier.find(identifier_id)
      int_name = i.internal_data.where(data_type: 'publicationName')
      int_name.each do |namer|
        namer.update(value: new_title)
      end
      int_issn = i.internal_data.where(data_type: 'publicationISSN').first
      if int_issn.blank?
        StashEngine::InternalDatum.create(identifier_id: i.id, data_type: 'publicationISSN', value: new_issn)
      else
        int_issn.update(value: new_issn)
      end
    end

    # Update the journal settings for a single Identifier
    def self.update_journal_for_resource(resource_id:, new_title:, new_issn:)
      pub = StashEngine::ResourcePublication.find_by(resource_id: resource_id)
      pub.update(publication_name: new_title, publication_issn: new_issn)
    end

    def as_json(_options = {})
      super(
        include: {
          payment_configuration: { only: %i[payment_plan covers_dpc covers_ldf ldf_limit yearly_ldf_fee_limit] }
        }
      )
    end

    def sponsored_identifiers
      StashEngine::Identifier.where("payment_type like 'journal-%'").where(payment_id: issn_array).distinct
    end

    def payment_sponsor
      # top level publisher
      top_level_org
    end

    def limits_sponsor
      sponsor
    end
  end
end
