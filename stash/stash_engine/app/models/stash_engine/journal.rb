module StashEngine
  class Journal < ApplicationRecord
    validates :issn, uniqueness: true
    has_many :journal_roles
    has_many :users, through: :journal_roles
    belongs_to :sponsor, class_name: 'JournalOrganization', optional: true

    def will_pay?
      payment_plan_type == 'SUBSCRIPTION' ||
        payment_plan_type == 'PREPAID' ||
        payment_plan_type == 'DEFERRED'
    end

    # Replace an uncontrolled journal name (typically containing '*')
    # with a controlled journal reference, using an id
    def self.replace_uncontrolled_journal(old_name:, new_id:)
      j = StashEngine::Journal.find(new_id)
      data = StashEngine::InternalDatum.where("value = '#{old_name}'")
      idents = data.map(&:identifier_id)
      idents.each do |ident|
        puts "  converting journal for #{ident}"
        update_journal_for_identifier(new_title: j.title, new_issn: j.issn, identifier_id: ident)
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
