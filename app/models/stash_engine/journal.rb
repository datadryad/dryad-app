# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  allow_review_workflow   :boolean          default(TRUE)
#  api_contacts            :text(65535)
#  default_to_ppr          :boolean          default(FALSE)
#  description             :text(65535)
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
    accepts_nested_attributes_for(*%i[issns alternate_titles payment_configuration])

    scope :servers, -> { where(preprint_server: true) }
    scope :sponsoring, -> { joins(:payment_configuration).where(payment_configuration: { payment_plan: PAYMENT_PLANS }) }

    def will_pay?
      PAYMENT_PLANS.include?(payment_configuration&.payment_plan)
    end

    def api_journal?
      StashEngine::Journal.api_journals.map(&:id).include?(id)
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
      # return nil unless issn.present?
      # return issn.first if issn.is_a?(Array)
      # return JSON.parse(issn)&.first if issn.start_with?('[')

      issns.map(&:id)&.first
    end

    # Return an array of ISSNs, even if the journal contains a single ISSN
    def issn_array
      # return nil unless issn.present?
      # return issn if issn.is_a?(Array)
      # return JSON.parse(issn) if issn.start_with?('[')

      issns.map(&:id)
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
      api_journals = StashEngine::Journal.joins(users: :api_application).distinct
      api_journals2 = StashEngine::JournalOrganization.joins(users: :api_application).map(&:journals_sponsored_deep).flatten
      api_journals | api_journals2
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
  end
end
