require_relative '../../mailer_spec_helper'

module StashEngine

  describe UserMailer do
    include MailerSpecHelper
    let(:journal) { create(:journal) }
    let(:journal_issn) { create(:journal_issn, journal: journal) }

    before(:each) do

      # TODO: this is completely ridiculous for number of mocks and we should be using factorybot instead and only disbling some callbacks

      @delivery_method = ActionMailer::Base.delivery_method
      ActionMailer::Base.delivery_method = :test

      @request_host = 'stash.example.org'
      @request_port = 80

      @user = create(:user)
      @resource = create(:resource, user: @user, identifier: create(:identifier), journal_issn: journal.issns.first)
      @identifier = @resource.identifier

      @tenant = double(Tenant)
      allow(@tenant).to receive(:campus_contacts).and_return(%w[gorgath@example.edu lajuana@example.edu])

      @author1 = @resource.authors.first

      @author2 = create(:author,
                        author_first_name: @user.first_name,
                        author_last_name: @user.last_name,
                        author_email: @user.email,
                        author_orcid: @user.orcid,
                        resource_id: @resource.id)

      @share = double(Share)
      allow(@share).to receive(:sharing_link).and_return("https://#{@request_host}/my_amazing_sharing_link")

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
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
      ActionMailer::Base.delivery_method = @delivery_method
    end

    describe 'curation status changes' do

      mailable = %w[peer_review submitted published embargoed withdrawn]
      # mailable = %w[peer_review]

      StashEngine::CurationActivity.statuses.each_key do |status|

        if mailable.include?(status)
          it "should send an email when '#{status}'" do
            allow(@resource).to receive(:current_curation_status).and_return(status)
            allow(@resource).to receive(:publication_date).and_return(Time.now.utc.to_date)

            UserMailer.status_change(@resource, status).deliver_now
            delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")

            case status
            when 'peer_review'
              expect(delivery.body.to_s).to include(@resource.identifier.shares.first.sharing_link)
              expect(delivery.body.to_s).to include('your submission will not enter our curation process for review and publication')
            when 'submitted'
              # expect(delivery.body.to_s).to include(@resource.identifier.shares.first.sharing_link)
              expect(delivery.body.to_s).to include('Thank you for your submission to Dryad')
            when 'published'
              expect(delivery.body.to_s).to include('approved for publication')
              expect(delivery.body.to_s).to include(@identifier.identifier.to_s)
            when 'embargoed'
              delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")
              expect(delivery.body.to_s).to include('will be embargoed until')
            when 'withdrawn'
              expect(delivery.body.to_s).to include('Your data submission has been withdrawn from the Dryad platform')
              expect(delivery.body.to_s).to include(@identifier.identifier.to_s)
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

      context 'title with HTML elements' do
        let(:status) { 'submitted' }

        it 'does not include HTML elements in the email subject' do
          allow(@resource).to receive(:title).and_return('A dataset title that contains <em>italics</em> and <sup>stuff</sup>')
          allow(@resource).to receive(:current_curation_status).and_return(status)
          UserMailer.status_change(@resource, status).deliver_now
          expect(@resource.title.strip_tags).to eq('A dataset title that contains italics and stuff')
          assert_email("[test] Dryad Submission \"#{@resource.title.strip_tags}\"")
        end
      end

      context 'when journal has peer_review_custom_text' do
        let(:status) { 'peer_review' }
        let(:journal) { create(:journal, peer_review_custom_text: 'This is a custom peer review message') }

        it 'contains the custom text' do
          allow(@resource).to receive(:current_curation_status).and_return(status)
          allow(@resource).to receive(:publication_date).and_return(Time.now.utc.to_date)

          UserMailer.status_change(@resource, status).deliver_now
          delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")

          expect(delivery.body.to_s).to include(@resource.identifier.shares.first.sharing_link)
          expect(delivery.body.to_s).to include('your submission will not enter our curation process for review and publication')
          expect(delivery.body.to_s).to include('This is a custom peer review message')
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
        allow(@resource).to receive(:publication_date).and_return(Time.now.utc.to_date)

        UserMailer.status_change(@resource, 'published').deliver_now
        delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")

        expect(delivery.body.to_s).to include('Your related software files are now published and publicly available on Zenodo')
        expect(delivery.body.to_s).to include('Your supplemental information is now published and publicly available on Zenodo')
        expect(delivery.body.to_s).to include(@test_doi)
        expect(delivery.body.to_s).to include(@test_doi2)
      end
    end

    describe 'embargoed status changes' do
      it "should send an modified email when embargoed_until_article_appears'" do
        allow(@resource).to receive(:current_curation_status).and_return('embargoed')
        allow(@resource).to receive(:publication_date).and_return(Time.now.utc.to_date)
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

      UserMailer.orcid_invitation(@invite).deliver_now
      delivery = assert_email("[test] Dryad Submission \"#{@resource.title}\"")
      expect(delivery.body.to_s).to include('we encourage you to link your ORCID iD to this publication by following the URL below')
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
  end
end
