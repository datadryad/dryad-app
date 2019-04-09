module StashDatacite
  # app/mailers/stash_datacite/user_mailer.rb
  class UserMailer < ApplicationMailer
    default from: APP_CONFIG['feedback_email_from'],
            return_path: 'dash2-dev@ucop.edu'
    # an example call:
    # UserMailer.notification(['catdog@mailinator.com', 'dogdog@mailinator.com'],
    #                           'that frosty mug taste', 'test_mail').deliver
    def notification(email_address, subject, message_template, locals)
      @vars = locals
      mail(
        to: to_address_from(email_address),
        subject: subject.to_s,
        from: APP_CONFIG['feedback_email_from'],
        reply_to: APP_CONFIG['feedback_email_from'],
        template_name: message_template
      )
    end

    def to_address_from(email_address)
      return email_address unless email_address.is_a?(Array)
      email_address.join(',')
    end
  end
end
