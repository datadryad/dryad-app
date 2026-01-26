describe CurationService do
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Datacite
  include Mocks::Stripe
  include Mocks::CurationActivity

  let(:identifier) { create(:identifier) }
  let(:user) { create(:user) }
  let(:curator) { create(:user, role: 'curator') }
  let(:resource) { create(:resource, user: user, identifier: identifier) }
  let(:status) { 'in_progress' }
  let(:service) { CurationService.new(resource: resource, user: curator, status: status) }

  before(:each) do
    mock_solr!
    mock_datacite_gen!
    mock_salesforce!
    mock_stripe!
  end

  describe '#process' do
    before { neuter_emails! }

    it 'calls #processed_sponsored_resource if status changes' do
      service.process

      expect(SponsoredPaymentsService).to receive_message_chain(:new, :log_payment).with(resource).with(no_args)
      CurationService.new(resource: resource, user: curator, status: 'queued').process
    end

    it 'does not call #processed_sponsored_resource if status does not change' do
      expect(SponsoredPaymentsService).not_to receive(:new)
      service.process
    end
  end

  context :submit_to_datacite do
    let(:resource_state) { create(:resource_state, :submitted, resource: resource) }
    let(:status) { 'published' }

    before(:each) do
      neuter_emails!
      resource.update(current_resource_state_id: resource_state.id)
    end

    it 'does submit when Published is set' do
      service.process
      expect(@mock_datacitegen).to have_received(:update_identifier_metadata!)
    end

    it "doesn't submit when a status besides Embargoed or Published is set" do
      CurationService.new(resource: resource, user: curator, status: 'to_be_published').process
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end

    it "doesn't submit when status isn't changed" do
      service.process
      expect(@mock_datacitegen).to have_received(:update_identifier_metadata!).once
      CurationService.new(resource: resource, user: curator, status: status).process
      expect(@mock_datacitegen).to have_received(:update_identifier_metadata!).once # should not be called for the second 'published'
    end

    it "doesn't submit if never sent to repo" do
      resource_state.update(resource_state: 'in_progress')
      service.process
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end

    it "doesn't submit if no version number" do
      resource.stash_version.update!(version: nil, merritt_version: nil)
      service.process
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end

    xit "doesn't submit non-production (test) identifiers after first version" do
      Timecop.travel(Time.now + 1.minute)
      resource2 = create(:resource, identifier: identifier)
      create(:resource_state, resource: resource2)
      resource2.stash_version.update(version: 2, merritt_version: 2)
      CurationService.new(resource: resource2, user: curator, status: status).process
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
      Timecop.return
    end

    context 'Datacite and EzId failures are properly handled' do
      let(:user) { create(:user, first_name: 'Test', last_name: 'User', email: 'test.user@example.org') }
      let(:status) { 'embargoed' }

      before(:each) do
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:should_update_doi?).and_return(true)
        logger = double(ActiveSupport::Logger)
        allow(logger).to receive(:error).with(any_args).and_return(true)
        allow(Rails).to receive(:logger).and_return(logger)
        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
      end

      it 'catches errors and emails the admins' do
        dc_error = Stash::Doi::DataciteGenError.new('Testing errors')
        allow(Stash::Doi::DataciteGen).to receive(:new).with(any_args).and_raise(dc_error)

        message = instance_double(ActionMailer::MessageDelivery)
        expect(StashEngine::UserMailer).to receive(:error_report).with(any_args).and_return(message)
        expect(message).to receive(:deliver_now)
        expect { service.process }.to raise_error(Stash::Doi::DataciteGenError)
      end
    end
  end

  context :submit_to_solr do
    before(:each) { neuter_emails! }

    it 'calls when published' do
      allow(resource).to receive(:submit_to_solr)
      expect(resource).to receive(:submit_to_solr)
      CurationService.new(resource: resource, user: curator, status: 'published').process
    end

    it 'calls when embargoed' do
      allow(resource).to receive(:submit_to_solr)
      expect(resource).to receive(:submit_to_solr)
      CurationService.new(resource: resource, user: curator, status: 'embargoed').process
    end

    it 'does not call if not published' do
      allow(resource).to receive(:submit_to_solr)
      expect(resource).not_to receive(:submit_to_solr)
      CurationService.new(resource: resource, user: curator, status: 'to_be_published').process
    end
  end

  context :process_payment do
    let(:status) { 'published' }

    context :charge_user_via_invoice do
      before(:each) do
        neuter_emails!
        @mock_invoicer = double('inv')
        allow(@mock_invoicer).to receive(:check_new_overages).and_return(true)
        allow(@mock_invoicer).to receive(:charge_user_via_invoice).and_return(true)
        allow(Stash::Payments::Invoicer).to receive(:new).and_return(@mock_invoicer)
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
      end

      it 'charges user when published' do
        service.process
        expect(@mock_invoicer).to have_received(:charge_user_via_invoice)
      end

      it 'charges user when embargoed' do
        CurationService.new(user: curator, resource: resource, status: 'embargoed').process
        expect(@mock_invoicer).to have_received(:charge_user_via_invoice)
      end

      it 'does not charge user if not ready_for_payment' do
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(false)
        CurationService.new(user: curator, resource: resource, status: 'to_be_published').process
        expect(@mock_invoicer).not_to have_received(:charge_user_via_invoice)
      end

      it 'does not charge user if skip_datacite' do
        allow_any_instance_of(StashEngine::Resource).to receive(:skip_datacite_update).and_return(true)
        service.process
        expect(@mock_invoicer).not_to have_received(:charge_user_via_invoice)
      end

      it 'does not charge user when user is not responsible for payment' do
        allow_any_instance_of(StashEngine::Identifier).to receive(:user_must_pay?).and_return(false)
        service.process
        expect(@mock_invoicer).not_to have_received(:charge_user_via_invoice)
      end
    end

    describe 'calls proper Stash::Payments::Invoicer method' do
      let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'stripe-123', old_payment_system: true) }
      let(:res_1) { create(:resource, identifier: identifier, total_file_size: 103_807_000_000, skip_datacite_update: false) }
      subject { Stash::Payments::Invoicer.new(resource: res_1, curator: curator) }

      before(:each) { neuter_emails! }

      context 'on first publish' do
        it 'calls #charge_user_via_invoice' do
          expect(Stash::Payments::Invoicer).to receive(:new).with(resource: res_1, curator: curator).and_return(subject)
          expect(subject).to receive(:charge_user_via_invoice).and_return(true)
          CurationService.new(resource: res_1, status: 'published', note: 'first publish', user: curator).process
        end
      end

      context 'on second publish' do
        context 'if identifier has no last_invoiced_file_size value' do
          it 'it should not be processed by any invoicer' do
            expect(Stash::Payments::Invoicer).to receive(:new).with(resource: res_1, curator: curator).and_return(subject)
            expect(subject).to receive(:charge_user_via_invoice).and_return(true)
            CurationService.new(resource: res_1, status: 'published', note: 'first publish', user: curator).process

            Timecop.travel(1.minute) do
              res_2 = create(:resource, identifier: identifier, total_file_size: 104_807_000_000)
              expect(Stash::Payments::Invoicer).not_to receive(:new)
              expect(Stash::Payments::StripeInvoicer).not_to receive(:new)

              CurationService.new(resource: res_2, status: 'published', note: 'second publish', user: curator).process
            end
          end
        end

        context 'if identifier has last_invoiced_file_size value' do
          let(:identifier) do
            create(:identifier, payment_type: 'stripe', payment_id: 'stripe-123', last_invoiced_file_size: 100_000, old_payment_system: true)
          end

          it 'it should not be processed by any invoicer' do
            expect(Stash::Payments::Invoicer).to receive(:new).with(resource: res_1, curator: curator).and_return(subject)
            expect(subject).to receive(:charge_user_via_invoice).and_return(true)
            CurationService.new(resource: res_1, status: 'published', note: 'first publish', user: curator).process

            Timecop.travel(1.minute) do
              res_2 = create(:resource, identifier: identifier, total_file_size: 104_807_000_000)
              expect(Stash::Payments::Invoicer).not_to receive(:new)
              expect(Stash::Payments::StripeInvoicer).not_to receive(:new)

              CurationService.new(resource: res_2, status: 'published', note: 'second publish', user: curator).process
            end
          end
        end
      end
    end
  end

  context :email_status_change_notices do
    before(:each) do
      allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:journal_published_notice).and_return(true)
    end

    StashEngine::CurationActivity.statuses.each_key do |state|
      if %w[published embargoed peer_review queued withdrawn].include?(state)
        it "sends email when '#{state}'" do
          expect_any_instance_of(StashEngine::UserMailer).to receive(:status_change)
          CurationService.new(resource: resource, user: user, status: state).process
        end
      else
        it "does not send email when '#{state}'" do
          expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
          CurationService.new(resource: resource, user: curator, status: state).process
        end
      end
    end

    it "does not send email when resource is 'queued' a second time" do
      CurationService.new(resource: resource, user: user, status: 'queued').process
      CurationService.new(resource: resource, user: curator, status: 'peer_review').process
      expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
      CurationService.new(resource: resource, user: user, status: 'queued').process
    end

    it "does not send email when identifier is 'published' a second time" do
      CurationService.new(resource: resource, user: curator, status: 'published').process
      expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
      Timecop.travel(1.minute) do
        new_version = create(:resource, identifier: identifier)
        CurationService.new(user: curator, resource: new_version, status: 'published').process
      end
    end

    it "does not send email when 'queued' by a curator" do
      expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
      CurationService.new(resource: resource, user: curator, status: 'queued').process
    end
  end

  context :email_orcid_invitations do
    before(:each) do
      @author = create(:author, author_orcid: nil, resource: resource)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation).and_return(true)
      allow_any_instance_of(StashEngine::Author).to receive(:affiliation).and_return(
        { long_name: 'Western New Mexico University', ror_id: 'https://ror.org/00r5mr697' }.to_ostruct
      )
    end

    it 'calls email_orcid_invitations when published' do
      expect_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation)
      CurationService.new(resource: resource, user: curator, status: 'published').process
    end

    it 'does not call email_orcid_invitations to authors who already have an invitation' do
      StashEngine::OrcidInvitation.create(identifier_id: identifier.id, email: @author.author_email, invited_at: Time.now)
      expect(StashEngine::UserMailer).not_to receive(:orcid_invitation)
      CurationService.new(resource: resource, user: curator, status: 'published').process
    end

    it 'does not call email_orcid_invitations to authors who already have an ORCID registered' do
      @author.update(author_orcid: user.orcid)
      expect(StashEngine::UserMailer).not_to receive(:orcid_invitation)
      CurationService.new(resource: resource, user: curator, status: 'published').process
    end
  end

  context :notify_partner_of_large_data_submission do
    let(:identifier) { create(:identifier) }
    let(:resource) { create(:resource, identifier: identifier) }
    let(:mock_cost_reporting_service) { instance_double(CostReportingService) }

    before do
      allow_any_instance_of(StashEngine::UserMailer).to receive(:journal_published_notice).and_return(true)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
      allow(CostReportingService).to receive(:new).with(resource).and_return(mock_cost_reporting_service)
    end

    context 'when status changes' do
      before do
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:curation_status_changed?).and_return(true)
      end

      %w[queued embargoed published].each do |status|
        it "calls notify_partner_of_large_data_submission on #{status}" do
          expect(mock_cost_reporting_service).to receive(:notify_partner_of_large_data_submission)
          CurationService.new(resource: resource, user: curator, status: status).process
        end
      end

      (StashEngine::CurationActivity.statuses.keys - %w[queued embargoed published]).each do |status|
        it "does not call notify_partner_of_large_data_submission on #{status}" do
          expect(mock_cost_reporting_service).not_to receive(:notify_partner_of_large_data_submission)
          CurationService.new(resource: resource, user: curator, status: status).process
        end
      end
    end

    context 'when status does not change' do
      before do
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:curation_status_changed?).and_return(false)
      end

      %w[queued embargoed published].each do |status|
        it "does not call notify_partner_of_large_data_submission on #{status}" do
          expect(mock_cost_reporting_service).not_to receive(:notify_partner_of_large_data_submission)
          CurationService.new(resource: resource, user: curator, status: status).process
        end
      end
    end
  end

  context :update_publication_flags do
    before(:each) { neuter_emails! }

    it 'sets flags for embargo' do
      CurationService.new(resource: resource, user: curator, status: 'embargoed').process

      expect(identifier.pub_state).to eq('embargoed')
      expect(resource.meta_view).to eq(true)
      expect(resource.file_view).to eq(false)
    end

    context 'changing status to published' do
      let(:status) { 'published' }

      it 'sets flags for published with file changes' do
        create(:data_file, download_filename: 'fun.cat', upload_file_size: 666, resource: resource)
        resource.reload
        service.process

        expect(identifier.pub_state).to eq('published')
        expect(resource.meta_view).to eq(true)
        expect(resource.file_view).to eq(true)
      end

      context 'when there is another published resource' do
        before(:each) do
          # set initial resource to published
          create(:data_file, download_filename: 'fun.cat', upload_file_size: 666, resource: resource)
          resource.reload
          service.process

          expect(identifier.pub_state).to eq('published')
          expect(resource.meta_view).to eq(true)
          expect(resource.file_view).to eq(true)
        end

        it 'sets flags for published with no file changes' do
          Timecop.travel(1.minute) do
            # new version
            new_resource = create(:resource, identifier: identifier)
            CurationService.new(resource: new_resource, user: curator, status: 'published').process

            expect(identifier.pub_state).to eq('published')
            expect(new_resource.meta_view).to eq(true)
            expect(new_resource.file_view).to eq(false)
          end
        end

        context 'when the resource is set to embargoed after publishing' do
          # set published initial resource to embargoed => file_view = false
          # create new version
          # set to published without files changes => file_view = false
          # set initial resource to published => file_view = true
          it 'sets flags for published with file changes' do
            # set initial resource to embargoed => file_view = false
            CurationService.new(resource: resource, user: curator, status: 'embargoed').process
            expect(resource.meta_view).to eq(true)
            expect(resource.file_view).to eq(false)

            Timecop.travel(1.minute) do
              # new version
              resource_2 = create(:resource, identifier: identifier)
              # set to published without files changes => file_view = false
              CurationService.new(resource: resource_2, user: curator, status: 'published').process

              expect(identifier.pub_state).to eq('published')
              expect(resource.meta_view).to eq(true)
              expect(resource.file_view).to eq(false)
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)

              # set initial resource to published => file_view = true
              CurationService.new(resource: resource, user: curator, status: 'published').process

              expect(identifier.pub_state).to eq('published')
              expect(resource.meta_view).to eq(true)
              expect(resource.file_view).to eq(true)
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)
            end
          end
        end

        context 'a huge sequence of published resources' do
          # create new version
          # set to publish without file changes => file_view = false
          # create another version
          # set to publish after adding a file => file_view = true
          # create another version
          # set to publish without file changes => file_view = false
          # create another version
          # set to publish after adding a file => file_view = true
          it 'sets flags for published with file changes' do
            Timecop.travel(1.minute) do
              # create new version
              resource_2 = create(:resource, identifier: identifier)
              # set to publish without file changes => file_view = false
              CurationService.new(resource: resource_2, user: curator, status: 'published').process

              expect(identifier.pub_state).to eq('published')
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)

              Timecop.travel(1.minute) do
                # create another version
                resource_3 = create(:resource, identifier: identifier)
                create(:data_file, resource: resource_3, download_filename: 'fun2.cat', upload_file_size: 666)
                resource_3.reload

                # set to publish after adding a file => file_view = true
                CurationService.new(resource: resource_3, user: curator, status: 'published').process

                expect(identifier.pub_state).to eq('published')
                expect(resource_3.meta_view).to eq(true)
                expect(resource_3.file_view).to eq(true)

                Timecop.travel(1.minute) do
                  # create another version
                  resource_4 = create(:resource, identifier: identifier)
                  CurationService.new(resource: resource_4, user: curator, status: 'published').process

                  expect(identifier.pub_state).to eq('published')
                  expect(resource_4.meta_view).to eq(true)
                  expect(resource_4.file_view).to eq(false)

                  Timecop.travel(1.minute) do
                    # create another version
                    resource_5 = create(:resource, identifier: identifier)
                    create(:data_file, resource: resource_5, download_filename: 'fun3.cat', upload_file_size: 666)
                    resource_5.reload
                    # set to publish after adding a file => file_view = true
                    CurationService.new(resource: resource_5, user: curator, status: 'published').process

                    expect(identifier.pub_state).to eq('published')
                    expect(resource_5.meta_view).to eq(true)
                    expect(resource_5.file_view).to eq(true)
                  end
                end
              end
            end
          end
        end
      end
    end

    it 'sets flags for withdrawn' do
      CurationService.new(resource: resource, user: curator, status: 'withdrawn').process
      expect(identifier.pub_state).to eq('withdrawn')
      expect(resource.meta_view).to eq(false)
      expect(resource.file_view).to eq(false)
    end

    context :peer_review_status do
      it 'disables the default peer_review setting after publication' do
        resource.update(hold_for_peer_review: true)
        CurationService.new(user: user, resource: resource, status: 'peer_review').process
        CurationService.new(user: user, resource: resource, status: 'published').process
        expect(resource.hold_for_peer_review?).to eq(false)
      end
    end
  end

  describe '#copy_to_zenodo' do
    let(:status) { 'published' }
    before(:each) { neuter_emails! }

    it 'calls two zenodo methods to copy software and supplemental' do
      expect(resource).to receive(:send_software_to_zenodo).with(publish: true).and_return('test2')
      expect(resource).to receive(:send_supp_to_zenodo).with(publish: true).and_return('test3')
      service.process
    end
  end

  describe '#processed_sponsored_resource' do
    %w[queued peer_review].each do |status|
      it "calls log_payment if status is #{status}" do
        service.process

        expect(SponsoredPaymentsService).to receive_message_chain(:new, :log_payment).with(resource).with(no_args)
        CurationService.new(resource: resource, user: curator, status: status).process
      end
    end

    (StashEngine::CurationActivity.statuses.keys - %w[queued peer_review]).each do |status|
      it "does not call log_payment if status is #{status}" do
        service.process

        expect(SponsoredPaymentsService).not_to receive(:new)
        CurationService.new(resource: resource, user: curator, status: status).process
      end
    end
  end
end
