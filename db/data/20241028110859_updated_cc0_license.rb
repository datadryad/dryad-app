# frozen_string_literal: true

class UpdatedCc0License < ActiveRecord::Migration[7.0]
  def up
    StashDatacite::Right.where(rights: 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication')
                        .update_all(rights: 'Creative Commons Zero v1.0 Universal', rights_uri: 'https://spdx.org/licenses/CC0-1.0.html')
    aaa
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
