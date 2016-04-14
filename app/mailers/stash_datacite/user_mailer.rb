module StashDatacite
  class UserMailer < ApplicationMailer
  default from: APP_CONFIG['feedback_email_from'],
          return_path: 'dash2-dev@ucop.du'

  #an example call:
  # UsersMailer.notification(['catdog@mailinator.com', 'dogdog@mailinator.com'],
  #                           'that frosty mug taste', 'test_mail').deliver
  def notification(email_address, subject, message_template, locals)
    if email_address.class == Array
      email_address_array = email_address
    else
      email_address_array = [email_address]
    end
    @vars = locals
    mail( :to             => email_address_array.join(','),
          :subject        => "#{subject}",
          :from           => APP_CONFIG['feedback_email_from'],
          :reply_to       => APP_CONFIG['feedback_email_from'],
          :template_name  => message_template
    )
  end
  end
end
