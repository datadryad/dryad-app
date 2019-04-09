require 'spec_helper'

module StashEngine

  describe UserMailer do

    before(:each) do
      @delivery_method = ActionMailer::Base.delivery_method
      stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base._view_paths.push("#{stash_engine_path}/app/views")

      @request_host = 'stash.example.org'
      @request_port = 80

      @identifier = double(Identifier)
      allow(@identifier).to receive(:identifier).and_return('10.1098/rstl.1665.0007')
      allow(@identifier).to receive(:identifier_type).and_return('DOI')
      allow(@identifier).to receive(:publication_issn).and_return(nil)
      allow(@identifier).to receive(:citations).and_return(["https://doi.org/#{@identifier.identifier}"])

      @tenant = double(Tenant)
      allow(@tenant).to receive(:campus_contacts).and_return(%w[gorgath@example.edu lajuana@example.edu])

      @user = double(User)
      allow(@user).to receive(:first_name).and_return('Jane')
      allow(@user).to receive(:last_name).and_return('Doe')
      allow(@user).to receive(:name).and_return('Jane Doe')
      allow(@user).to receive(:email).and_return('jane.doe@example.edu')
      allow(@user).to receive(:tenant).and_return(@tenant)

      @author1 = double(Author)
      allow(@author1).to receive(:author_first_name).and_return(@user.first_name)
      allow(@author1).to receive(:author_last_name).and_return(@user.last_name)
      allow(@author1).to receive(:author_email).and_return(@user.email)
      allow(@author1).to receive(:author_standard_name).and_return(@user.name)

      @author2 = double(Author)
      allow(@author2).to receive(:author_first_name).and_return('Foo')
      allow(@author2).to receive(:author_last_name).and_return('Bar')
      allow(@author2).to receive(:author_email).and_return('foo.bar@example.edu')

      @share = double(Share)
      allow(@share).to receive(:sharing_link).and_return("https://#{@request_host}/my_amazing_sharing_link")

      @resource = double(Resource)
      allow(@resource).to receive(:user).and_return(@user)
      allow(@resource).to receive(:identifier).and_return(@identifier)
      allow(@resource).to receive(:identifier_str).and_return(@identifier.identifier)
      allow(@resource).to receive(:identifier_uri).and_return("https://#{@request_host}/#{@identifier}")
      allow(@resource).to receive(:share).and_return(@share)
      allow(@resource).to receive(:title).and_return('An Account of a Very Odd Monstrous Calf')
      allow(@resource).to receive(:tenant).and_return(@tenant)
      allow(@resource).to receive(:files_published?).and_return(true)
      allow(@resource).to receive(:authors).and_return([@author1, @author2])

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

    describe 'curation status changes' do

      mailable = %w[peer_review submitted published embargoed]

      StashEngine::CurationActivity.statuses.each do |status|

        if mailable.include?(status)
          it "should send an email when '#{status}'" do
            allow(@resource).to receive(:current_curation_status).and_return(status)
            allow(@resource).to receive(:publication_date).and_return(Date.today)

            UserMailer.status_change(@resource, status).deliver_now
            delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")

            case status
            when 'peer_review'
              expect(delivery.body.to_s).to include(@resource.share.sharing_link)
              expect(delivery.body.to_s).to include('Your dataset will now remain private until your related manuscript has been accepted.')
            when 'submitted'
              expect(delivery.body.to_s).to include(@resource.share.sharing_link)
              expect(delivery.body.to_s).to include('You should receive an update within two business days.')
            when 'published'
              expect(delivery.body.to_s).to include('Your dataset is now published and public.')
              expect(delivery.body.to_s).to include("We recommend that you cite it using this DOI: #{@identifier.identifier}")
            when 'embargoed'
              delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")
              expect(delivery.body.to_s).to include('will be embargoed until')
            end
          end
        else
          it "should not send an email when '#{status}'" do
            allow(@resource).to receive(:current_curation_status).and_return(status)
            UserMailer.status_change(@resource, status).deliver_now
            assert_no_email
          end
        end

      end

    end

    it 'sends an invitation' do
      @invite = double(OrcidInvitation)
      allow(@invite).to receive(:resource).and_return(@resource)
      allow(@invite).to receive(:tenant).and_return(@resource.tenant)
      allow(@invite).to receive(:identifier).and_return(@identifier.identifier)
      allow(@invite).to receive(:secret).and_return('my_secret')
      allow(@invite).to receive(:landing).and_return("https://#{@request_host}/fake_invite")
      allow(@invite).to receive(:email).and_return(@user.email)
      allow(@invite).to receive(:first_name).and_return(@user.email)
      allow(@invite).to receive(:last_name).and_return(@user.email)

      url_helpers = double(Module)
      routes = double(Module)
      allow(url_helpers).to receive(:show_path).and_return(@resource.identifier_uri)
      allow(routes).to receive(:url_helpers).and_return(url_helpers)
      allow(StashEngine::Engine).to receive(:routes).and_return(routes)

      UserMailer.orcid_invitation(@invite).deliver_now
      delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")
      expect(delivery.body.to_s).to include('We encourage you to register your ORCID researcher information for this dataset')
    end

    describe 'failures' do

      it 'sends a submission failure email' do
        error = ArgumentError.new
        UserMailer.submission_failed(@resource, error).deliver_now
        delivery = assert_email("[test] Dryad Submission Failure \"#{@resource.title}\"")
        expect(delivery.body.to_s).to include('An error occurred while submitting your dataset')
      end

      it 'sends an error report email' do
        error = ArgumentError.new
        UserMailer.error_report(@resource, error).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        expect(deliveries[0].body.to_s).to include('The error details are below.')
      end

    end

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
        'From' => APP_CONFIG['feedback_email_from'] || APP_CONFIG['helpdesk_email'] || 'help@datadryad.org',
        'To' => @user.email,
        'Subject' => expected_subject
      }

      headers = header.fields.map { |field| [field.name, field.value] }.to_h
      expected_headers.each do |k, v|
        expect(headers[k]).to eq(v)
      end
    end

  end

end
