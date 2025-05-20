# frozen_string_literal: true

# == Schema Information
#
# Table name: stash_engine_external_references
#
#  id            :integer          not null, primary key
#  source        :string(191)
#  value         :text(4294967295)
#  created_at    :datetime
#  updated_at    :datetime
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_external_references_on_identifier_id  (identifier_id)
#  index_stash_engine_external_references_on_source         (source)
#
module StashEngine
  # This class is currently used to store identifiers for external GenBank databases
  # used by the LinkOut functionality. It is similar to the InternalDatum model except
  # that the `value` is a Text field
  #
  # The primary difference between this model and `InternalDatum` is that a curator
  # is not meant to be able to create/update/delete this data
  class ExternalReference < ApplicationRecord
    self.table_name = 'stash_engine_external_references'

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
    enum :source, enum_vals.index_by(&:to_sym), default: 'nuccore', validate: { message: '%{value} is not a valid source' }

    validates :identifier, :value, presence: true
    validates :source, uniqueness: { case_sensitive: false, scope: :identifier, message: 'the dataset already has an entry for %{value}' }
  end
end
