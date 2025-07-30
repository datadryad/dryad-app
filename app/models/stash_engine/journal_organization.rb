# == Schema Information
#
# Table name: stash_engine_journal_organizations
#
#  id            :bigint           not null, primary key
#  name          :string(191)
#  contact       :string(191)
#  parent_org_id :integer
#  type          :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
module StashEngine
  class JournalOrganization < ApplicationRecord
    self.table_name = 'stash_engine_journal_organizations'
    validates :name, presence: true
    validate :email_array

    has_many :children, class_name: 'JournalOrganization', primary_key: :id, foreign_key: :parent_org_id, inverse_of: :parent_org
    belongs_to :parent_org, class_name: 'JournalOrganization', optional: true, inverse_of: :children
    has_many :journals_sponsored, class_name: 'StashEngine::Journal', foreign_key: :sponsor_id
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object, dependent: :destroy
    has_many :users, through: :roles

    scope :has_children, -> { distinct.joins(:children) }

    # Treat the 'type' column as a string, not a single-inheritance class name
    self.inheritance_column = :_type_disabled

    def contact
      JSON.parse(super) unless super.nil?
    end

    def email_array
      contact&.each do |email|
        errors.add(:contact, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
      end
    end

    # journals sponsored at any level by this org and its children
    def journals_sponsored_deep
      j = journals_sponsored
      orgs_included&.each do |suborg|
        j |= suborg.journals_sponsored
      end
      j
    end

    # All organizations that are part of this organization,
    # at any level of hierarchy
    def orgs_included
      return nil if children.blank?

      all_orgs = []

      children.each do |sub|
        all_orgs << sub
        all_orgs |= sub.orgs_included if sub.children.present?
      end
      all_orgs
    end
  end
end
