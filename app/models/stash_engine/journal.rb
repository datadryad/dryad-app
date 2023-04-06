module StashEngine
  class Journal < ApplicationRecord
    self.table_name = 'stash_engine_journals'
    validates :issn, uniqueness: { case_sensitive: false }
    has_many :alternate_titles, class_name: 'JournalTitle', dependent: :destroy
    has_many :journal_roles
    has_many :users, through: :journal_roles
    belongs_to :sponsor, class_name: 'JournalOrganization', optional: true

    def will_pay?
      payment_plan_type == 'SUBSCRIPTION' ||
        payment_plan_type == 'PREPAID' ||
        payment_plan_type == 'DEFERRED' ||
        payment_plan_type == 'TIERED'
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
      return nil unless issn.present?
      return issn.first if issn.is_a?(Array)
      return JSON.parse(issn)&.first if issn.start_with?('[')

      issn
    end

    # Return an array of ISSNs, even if the journal contains a single ISSN
    def issn_array
      return nil unless issn.present?
      return issn if issn.is_a?(Array)
      return JSON.parse(issn) if issn.start_with?('[')

      [issn]
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

      StashEngine::Journal.where("issn like '%#{issn}%'")&.first
    end

    # Replace an uncontrolled journal name (typically containing '*')
    # with a controlled journal reference, using an id
    def self.replace_uncontrolled_journal(old_name:, new_id:)
      j = StashEngine::Journal.find(new_id)
      data = StashEngine::InternalDatum.where("value = '#{old_name}'")
      idents = data.map(&:identifier_id)
      idents.each do |ident|
        puts "  converting journal for #{ident}"
        update_journal_for_identifier(new_title: j.title, new_issn: j.single_issn, identifier_id: ident)
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

  end
end
