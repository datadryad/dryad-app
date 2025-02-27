# frozen_string_literal: true

class AddCorresp < ActiveRecord::Migration[7.0]
  def up
    StashEngine::Author.where.not(author_email: [nil, '']).update_all(corresp: true)
  end

  def down
    StashEngine::Author.update_all(corresp: false)
  end
end
