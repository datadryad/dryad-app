module StashEngine
  class Author < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    before_save :strip_whitespace

    scope :names_filled, -> { where("TRIM(IFNULL(author_first_name,'')) <> ''") }

    def author_full_name
      [author_last_name, author_first_name].reject(&:blank?).join(', ')
    end

    # TODO: replace these with :author_orcid=
    def orcid_id=(value)
      self.author_orcid = (value.trim unless value.blank?)
    end

    # TODO: replace these with :author_orcid
    def orcid_id
      self.author_orcid
    end

    private

    def strip_whitespace
      self.author_first_name = author_first_name.strip if author_first_name
      self.author_last_name = author_last_name.strip if author_last_name
      self.author_email = author_email.strip if author_email
      self.author_orcid = author_orcid.strip if author_orcid
    end
  end
end
