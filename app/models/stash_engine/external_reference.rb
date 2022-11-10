# frozen_string_literal: true

module StashEngine
  # This class is currently used to store identifiers for external GenBank databases
  # used by the LinkOut functionality. It is similar to the InternalDatum model except
  # that the `value` is a Text field
  #
  # The primary difference between this model and `InternalDatum` is that a curator
  # is not meant to be able to create/update/delete this data
  class ExternalReference < ApplicationRecord
    self.table_name = 'stash_engine_external_references'
    include StashEngine::Support::StringEnum

    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # List of possible external sources
    enum_vals = %w[
      bioproject
      gene
      nuccore
      nucest
      nucgss
      nucleotide
      protein
      taxonomy
    ]
    string_enum('source', enum_vals, 'nuccore', false)

    validates :source, inclusion: { in: enum_vals, message: '%{value} is not a valid source' }
    validates :identifier, :value, presence: true
    validates :source, uniqueness: { case_sensitive: false, scope: :identifier, message: 'the dataset already has an entry for %{value}' }
  end
end
