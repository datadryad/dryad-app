module MailerSpecHelper

  private

  def assert_email(expected_subject)
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    assert_email_headers(deliveries[0].header, expected_subject)
    deliveries[0]
  end

  def assert_no_email
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  def assert_email_headers(header, expected_subject)
    expected_headers = {
      'From' => APP_CONFIG[:contact_email].last,
      'To' => @user.email,
      'Subject' => expected_subject
    }

    headers = header.fields.to_h { |field| [field.name, field.value] }
    expected_headers.each do |k, v|
      expect(headers[k]).to eq(v)
    end
  end
end
