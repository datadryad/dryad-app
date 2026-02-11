# frozen_string_literal: true

class FixCitationMetadata < ActiveRecord::Migration[8.0]
  def up
    StashEngine::CounterCitation.where.not(metadata: [nil, '']).find_each do |c|
      c.update(metadata: JSON.parse(c.metadata))
    end
  end

  def down
    # never previously used
  end
end
