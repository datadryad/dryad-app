# frozen_string_literal: true

class SetApiTokensWithProperScopes < ActiveRecord::Migration[8.0]
  def change
    Doorkeeper::AccessToken.where(created_at: [36000.seconds.ago..]).where(scopes: ['', nil]).update_all(scopes: 'all')
  end
end
