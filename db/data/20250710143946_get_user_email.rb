# frozen_string_literal: true

class GetUserEmail < ActiveRecord::Migration[8.0]
  def up
    StashEngine::User.where(email: [nil, '']).joins(:resources).distinct.find_each do |u|
      r = u.resources.last
      a = r.authors.where(author_orcid: u.orcid).first
      next unless a&.author_email.present?

      u.update_columns(email: a.author_email)
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
