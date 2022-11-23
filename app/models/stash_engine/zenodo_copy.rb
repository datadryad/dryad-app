module StashEngine
  # this class has a bit of a peculiar structure and there could be multple third copy items for an identifier,
  # however there should only be one per resource (update the status and we'll have updated timestamps which is really all we need)
  # since this set of states is very simple
  class ZenodoCopy < ApplicationRecord
    self.table_name = 'stash_engine_zenodo_copies'
    include StashEngine::Support::StringEnum

    belongs_to :identifier, class_name: 'StashEngine::Identifier'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    string_enum('state', %w[enqueued replicating finished error], 'enqueued', false)
    string_enum('copy_type', %w[data software software_publish supp supp_publish], 'data', false)

    scope :data, -> { where(copy_type: 'data') }
    scope :software, -> { where(copy_type: %w[software software_publish]) }
    scope :supp, -> { where(copy_type: %w[supp supp_publish]) }

    scope :done, -> { where('deposition_id IS NOT NULL').where(state: 'finished') }

    def self.last_copy_with_software(identifier_id:)
      joins('INNER JOIN stash_engine_generic_files gf ON stash_engine_zenodo_copies.resource_id = gf.resource_id')
        .where('stash_engine_zenodo_copies.identifier_id = ?', identifier_id)
        .where('stash_engine_zenodo_copies.software_doi IS NOT NULL')
        .where('stash_engine_zenodo_copies.copy_type LIKE "software%"')
        .where('gf.type = "StashEngine::SoftwareFile"')
        .where("gf.file_state IN ('created', 'copied')")
        .order('stash_engine_zenodo_copies.id DESC').first
    end

    def self.last_copy_with_supp(identifier_id:)
      joins('INNER JOIN stash_engine_generic_files gf ON stash_engine_zenodo_copies.resource_id = gf.resource_id')
        .where('stash_engine_zenodo_copies.identifier_id = ?', identifier_id)
        .where('stash_engine_zenodo_copies.software_doi IS NOT NULL')
        .where('stash_engine_zenodo_copies.copy_type LIKE "supp%"')
        .where('gf.type = "StashEngine::SuppFile"')
        .where("gf.file_state IN ('created', 'copied')")
        .order('stash_engine_zenodo_copies.id DESC').first
    end
  end
end
