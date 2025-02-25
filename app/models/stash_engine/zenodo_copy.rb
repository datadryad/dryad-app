# == Schema Information
#
# Table name: stash_engine_zenodo_copies
#
#  id            :integer          not null, primary key
#  conceptrecid  :string(191)
#  copy_type     :string           default("data")
#  error_info    :text(16777215)
#  note          :text(65535)
#  retries       :integer          default(0)
#  software_doi  :string(191)
#  state         :string           default("enqueued")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deposition_id :integer
#  identifier_id :integer
#  resource_id   :integer
#
# Indexes
#
#  index_stash_engine_zenodo_copies_on_conceptrecid   (conceptrecid)
#  index_stash_engine_zenodo_copies_on_copy_type      (copy_type)
#  index_stash_engine_zenodo_copies_on_deposition_id  (deposition_id)
#  index_stash_engine_zenodo_copies_on_identifier_id  (identifier_id)
#  index_stash_engine_zenodo_copies_on_note           (note)
#  index_stash_engine_zenodo_copies_on_resource_id    (resource_id)
#  index_stash_engine_zenodo_copies_on_retries        (retries)
#  index_stash_engine_zenodo_copies_on_software_doi   (software_doi)
#  index_stash_engine_zenodo_copies_on_state          (state)
#
module StashEngine
  # this class has a bit of a peculiar structure and there could be multple third copy items for an identifier,
  # however there should only be one per resource (update the status and we'll have updated timestamps which is really all we need)
  # since this set of states is very simple
  class ZenodoCopy < ApplicationRecord
    self.table_name = 'stash_engine_zenodo_copies'

    belongs_to :identifier, class_name: 'StashEngine::Identifier'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    enum :state, %w[enqueued replicating finished error deferred].index_by(&:to_sym), default: 'enqueued', validate: true
    enum :copy_type, %w[data software software_publish supp supp_publish].index_by(&:to_sym), default: 'data', validate: true

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
