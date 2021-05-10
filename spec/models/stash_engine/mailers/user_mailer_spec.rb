module StashEngine

  describe UserMailer do

    before(:each) do

      # TODO: this is completely ridiculous for number of mocks and we should be using factorybot instead and only disbling some callbacks

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
      allow(@identifier).to receive(:embargoed_until_article_appears?).and_return(false)

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
      allow(@resource).to receive(:title).and_return('An Account of a Very Odd Monstrous Calf')
      allow(@resource).to receive(:tenant).and_return(@tenant)
      allow(@resource).to receive(:files_published?).and_return(true)
      allow(@resource).to receive(:authors).and_return([@author1, @author2])
      allow(@resource).to receive(:identifier_value).and_return('10.1098/rstl.1665.0007')
      allow(@resource).to receive(:related_identifiers).and_return(nil)

      allow(@identifier).to receive(:shares).and_return([@share])

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
              expect(delivery.body.to_s).to include(@resource.identifier.shares.first.sharing_link)
              expect(delivery.body.to_s).to include('will now remain private until your related manuscript has been accepted.')
            when 'submitted'
              expect(delivery.body.to_s).to include(@resource.identifier.shares.first.sharing_link)
              expect(delivery.body.to_s).to include('Thank you for submitting your dataset')
            when 'published'
              expect(delivery.body.to_s).to include('Your dataset is now published and public.')
              expect(delivery.body.to_s).to include("Please cite it using this DOI: #{@identifier.identifier}")
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

    describe 'publication email' do

      before(:each) do
        # the fake resource is so I don't have to rewrite all tests just to test related id email and can begin using factories
        # in a limited way instead of mocking every possible method in the world.

        @fake_resource = create(:resource)
        @test_doi = "#{rand.to_s[2..6]}/zenodo.#{rand.to_s[2..11]}"
        @test_doi2 = "#{rand.to_s[2..6]}/zenodo.#{rand.to_s[2..11]}"

        create(:related_identifier, related_identifier: "https://doi.org/#{@test_doi}",
                                    resource_id: @fake_resource.id, added_by: 'zenodo', work_type: 'software')

        create(:related_identifier, related_identifier: "https://doi.org/#{@test_doi2}",
                                    resource_id: @fake_resource.id, added_by: 'zenodo', work_type: 'supplemental_information')

        allow(@resource).to receive(:related_identifiers).and_return(@fake_resource.related_identifiers)
      end

      it 'should show info about zenodo software doi and zenodo supplemental info when present' do
        allow(@resource).to receive(:current_curation_status).and_return('published')
        allow(@resource).to receive(:publication_date).and_return(Date.today)

        UserMailer.status_change(@resource, 'published').deliver_now
        delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")

        expect(delivery.body.to_s).to include('Your related software is being published at Zenodo')
        expect(delivery.body.to_s).to include('Your supplemental information is being published at Zenodo')
        expect(delivery.body.to_s).to include(@test_doi)
        expect(delivery.body.to_s).to include(@test_doi2)
      end
    end

    describe 'embargoed status changes' do
      it "should send an modified email when embargoed_until_article_appears'" do
        allow(@resource).to receive(:current_curation_status).and_return('embargoed')
        allow(@resource).to receive(:publication_date).and_return(Date.today)
        allow(@identifier).to receive(:embargoed_until_article_appears?).and_return(true)

        UserMailer.status_change(@resource, 'embargoed').deliver_now
        delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")
        expect(delivery.body.to_s).to include('until the associated article appears')
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

      it 'sends an error report email' do
        error = ArgumentError.new
        UserMailer.error_report(@resource, error).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        expect(deliveries[0].body.to_s).to include('The error details are below.')
      end

    end

    describe 'zenodo_error' do

      before(:each) do
        @res = create(:resource)
        @zen = create(:zenodo_copy, identifier: @res.identifier, resource: @res, state: 'error', error_info: 'Something bad just happened',
                                    software_doi: '10.2837/zenodo.bad_test', conceptrecid: '123345')
      end

      it 'send a zenodo error report' do
        UserMailer.zenodo_error(@zen).deliver_now
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        expect(deliveries[0].body.to_s).to include('Something bad just happened')
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
        'From' => APP_CONFIG[:contact_email].last,
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
