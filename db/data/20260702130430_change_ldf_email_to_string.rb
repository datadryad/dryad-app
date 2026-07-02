# frozen_string_literal: true

class ChangeLdfEmailToString < ActiveRecord::Migration[8.0]
  def up
    PaymentConfiguration.all.each do |pc|
      if pc.ldf_limit_notification == '0'
        pc.update_columns(ldf_limit_notification: nil) 
      elsif ldf_limit_notification == '1'
        email = if pc.partner.has_attribute?(:campus_contacts)
                  pc.partner.campus_contacts
                elsif pc.partner.has_attribute?(:contact)
                  pc.partner.contact
                end
        pc.update_columns(ldf_limit_notification: email)
      end
    end
  end

  def down
    PaymentConfiguration.all.each do |pc|
      pc.update_columns(ldf_limit_notification: pc.ldf_limit_notification.blank? ? '0' : '1')
    end
  end
end
