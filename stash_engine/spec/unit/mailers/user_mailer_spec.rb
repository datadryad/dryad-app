require 'spec_helper'

module StashEngine
  describe UserMailer do
    attr_reader :title
    attr_reader :doi
    attr_reader :doi_value
    attr_reader :request_host
    attr_reader :request_port
    attr_reader :user
    attr_reader :resource
    attr_reader :mailer
    attr_reader :tenant
    attr_reader :sender_address
    attr_reader :submission_error_address
    attr_reader :embargo

    before(:each) do
      @title = 'An Account of a Very Odd Monstrous Calf'
      @doi_value = '10.1098/rstl.1665.0007'
      @doi = "doi:#{doi_value}"
      @request_host = 'stash.example.org'
      @request_port = 80

      @tenant = double(Tenant)
      allow(tenant).to receive(:campus_contacts).and_return(%w[gorgath@example.edu lajuana@example.edu])

      @user = double(User)
      allow(user).to receive(:first_name).and_return('Jane')
      allow(user).to receive(:last_name).and_return('Doe')
      allow(user).to receive(:email).and_return('jane.doe@example.edu')
      allow(user).to receive(:tenant).and_return(tenant)

      @embargo = double(Embargo)
      allow(embargo).to receive(:end_date).and_return(Date.tomorrow.to_time(:utc))

      @resource = double(Resource)
      allow(resource).to receive(:user).and_return(user)
      allow(resource).to receive(:identifier_uri).and_return("https://doi.org/#{doi_value}")
      allow(resource).to receive(:identifier_value).and_return(doi_value)
      allow(resource).to receive(:title).and_return(title)
      allow(resource).to receive(:embargo).and_return(embargo)
      allow(resource).to receive(:tenant_id).and_return('ucop')
      allow(resource).to receive(:tenant).and_return(@tenant)
      allow(resource).to receive(:files_published?).and_return(true)

      @delivery_method = ActionMailer::Base.delivery_method
      ActionMailer::Base.delivery_method = :test

      stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
      # ActionView::ViewPaths.append_view_path("#{stash_engine_path}/app/views/stash_engine/user_mailer")
      ActionMailer::Base._view_paths.push("#{stash_engine_path}/app/views")

      @sender_address = APP_CONFIG['feedback_email_from']
      @submission_error_address = APP_CONFIG['submission_error_email']

      allow_any_instance_of(ActionView::Helpers::UrlHelper)
        .to receive(:url_for)
        .with(kind_of(String)) do |_, plain_url|
        plain_url
      end
      allow_any_instance_of(ActionView::Helpers::UrlHelper)
        .to receive(:url_for)
        .with(kind_of(Hash)) do |_, url_params|
        "http://#{url_params[:host]}:#{url_params[:port]}/#{url_params[:controller]}"
      end

      # this rails_root stuff is required when faking Rails like david did and using the mailer since it seems to call it
      rails_root = Dir.mktmpdir('rails_root')
      allow(Rails).to receive(:root).and_return(rails_root)
      allow(Rails).to receive(:application).and_return(OpenStruct.new(default_url_options: { host: 'stash.example.edu' }))
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
      ActionMailer::Base.delivery_method = @delivery_method
    end

    describe '#submission_succeeded' do
      it 'sends a success email' do
        UserMailer.submission_succeeded(@resource).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        delivery = deliveries[0]

        expected_headers = {
          'Return-Path' => sender_address,
          'From' => "Dash Notifications <#{sender_address}>",
          'To' => user.email,
          'Bcc' => 'alan.smithee@example.edu,gorgath@example.edu,lajuana@example.edu',
          'Subject' => "[#{ENV['RAILS_ENV']}] Dataset \"#{title}\" (#{doi}) submitted"
        }

        headers = delivery.header.fields.map { |field| [field.name, field.value] }.to_h
        expected_headers.each do |k, v|
          expect(headers[k]).to eq(v)
        end

        doi_href = "https://doi.org/#{doi_value}"
        expect(delivery.body.to_s).to include("<a href=\"#{doi_href}\">#{doi_href}</a>")
      end

      it 'omits the environment name in production' do
        allow(Rails).to receive(:env).and_return('production')
        begin
          UserMailer.submission_succeeded(resource).deliver_now
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(1)
          delivery = deliveries[0]
          headers = delivery.header.fields.map { |field| [field.name, field.value] }.to_h
          expect(headers['Subject']).to eq("Dataset \"#{title}\" (#{doi}) submitted")
        ensure
          allow(Rails).to receive(:env).and_call_original
        end
      end
    end

    describe '#submission_failed' do
      it 'sends a failure email' do
        error = ArgumentError.new
        UserMailer.submission_failed(@resource, error).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        delivery = deliveries[0]

        expected_headers = {
          'Return-Path' => sender_address,
          'From' => "Dash Notifications <#{sender_address}>",
          'To' => user.email,
          'Subject' => "[#{ENV['RAILS_ENV']}] Submitting dataset \"#{title}\" (#{doi}) failed"
        }

        headers = delivery.header.fields.map { |field| [field.name, field.value] }.to_h
        expected_headers.each do |k, v|
          expect(headers[k]).to eq(v)
        end

        doi_href = "https://doi.org/#{doi_value}"
        expect(delivery.body.to_s).to include("<a href=\"#{doi_href}\">#{doi_href}</a>")
      end
    end

    describe '#error_report' do
      it 'sends an error report email' do
        error = ArgumentError.new
        UserMailer.error_report(resource, error).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        delivery = deliveries[0]

        expected_headers = {
          'Return-Path' => sender_address,
          'From' => "Dash Notifications <#{sender_address}>",
          'To' => submission_error_address.join(','),
          'Bcc' => 'alan.smithee@example.edu',
          'Subject' => "[#{ENV['RAILS_ENV']}] Submitting dataset \"#{title}\" (#{doi}) failed"
        }

        headers = delivery.header.fields.map { |field| [field.name, field.value] }.to_h
        expected_headers.each do |k, v|
          expect(headers[k]).to eq(v)
        end

        body = delivery.body.to_s
        expect(body).to include("<a href=\"mailto:#{user.email}\">#{user.first_name} #{user.last_name}</a>")
        doi_href = "https://doi.org/#{doi_value}"
        expect(body).to include("<a href=\"#{doi_href}\">#{doi_href}</a>")
      end
    end
  end
end
