# frozen_string_literal: true

class ResourceRoles < ActiveRecord::Migration[7.0]
  def up
    StashEngine::Identifier.joins(:latest_resource).find_each do |idt|
      creator = idt.resources.first.curation_activities.first.user_id
      submitter = idt.latest_resource.user_id
      curator = idt.most_recent_curator&.id || nil
      idt.resources.update_all(user_id: curator)
      idt.resources.each do |r|
        next if r.submitter.present?
        
        StashEngine::Role.create(user_id: creator, role: 'creator', role_object: r)
        StashEngine::Role.create(user_id: submitter, role: 'submitter', role_object: r)
      end
    end
  end

  def down
    StashEngine::Identifier.joins(:latest_resource).find_each do |idt|
      idt.resources.each do |r|
        r.update_columns(user_id: r.submitter.id)
        r.roles.delete_all
      end
    end
  end
end
