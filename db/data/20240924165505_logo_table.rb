# frozen_string_literal: true

class LogoTable < ActiveRecord::Migration[7.0]
  def up
    StashEngine::Tenant.all.each do |t|
      moved = StashEngine::Logo.create(data: t.logo_id)
      t.update(logo_id: moved.id)
    end 
  end

  def down
    StashEngine::Tenant.all.each do |t|
      t.update(logo_id: t.logo.data)
    end
  end
end
