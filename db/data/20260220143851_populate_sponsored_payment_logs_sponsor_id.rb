# frozen_string_literal: true

class PopulateSponsoredPaymentLogsSponsorId < ActiveRecord::Migration[8.0]
  def up
    SponsoredPaymentLog.where(sponsor_id: nil).each do |item|
      item.update_column(:sponsor_id, item.payer&.sponsor_id)
    end
  end

  def down
  end
end
