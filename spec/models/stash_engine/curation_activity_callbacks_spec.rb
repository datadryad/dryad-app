require 'byebug'

module StashEngine
  describe CurationActivity, type: :model do

    include Mocks::Datacite
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe
    include Mocks::CurationActivity

    before(:each) do
      mock_solr!
      mock_datacite!
      mock_salesforce!
      mock_stripe!
      Timecop.travel(Time.now.utc - 1.minute)
      @identifier = create(:identifier, identifier_type: 'DOI', identifier: '10.123/123')
      @resource = create(:resource, identifier_id: @identifier.id, created_at: 5.minutes.ago)
      @curator = create(:user, role: 'curator')
      # reload so that it picks up any associated models that are initialized
      # (e.g. CurationActivity and ResourceState)
      @resource.reload
      Timecop.return
      allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
    end

    context :new do
      it 'defaults status to :in_progress' do
        activity = CurationActivity.new(resource: @resource)
        expect(activity.status).to eql('in_progress')
      end

      it 'requires a resource' do
        activity = CurationActivity.new(resource: nil)
        expect(activity.valid?).to eql(false)
      end
    end

    context :latest do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'returns the most recent activity' do
        ca2 = create(:curation_activity, resource: @resource, status: 'peer_review', note: 'this is a test')
        expect(CurationActivity.latest(resource: @resource)).to eql(ca2)
      end
    end

    context :readable_status do
      before(:each) do
        @ca = create(:curation_activity, resource: @resource)
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
      end

      it 'class method allows conversion of status to humanized status' do
        expect(CurationActivity.readable_status('submitted')).to eql('Submitted')
      end

      it 'returns a readable version of :peer_review' do
        @ca.peer_review!
        expect(@ca.readable_status).to eql('Private for peer review')
      end

      it 'returns a readable version of :action_required' do
        @ca.action_required!
        expect(@ca.readable_status).to eql('Action required')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each_key do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize)
          end
        end
      end
    end

    context :callbacks do
      context :update_solr do
        it 'calls update_solr when published' do
          @resource.update(publication_date: Time.now.utc.to_date.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published', user: @curator)
          expect(ca).to receive(:update_solr)
          ca.save
        end

        it 'calls update_solr when embargoed' do
          @resource.update(publication_date: (Time.now.utc.to_date + 1.day).to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed', user: @curator)
          expect(ca).to receive(:update_solr)
          ca.save
        end

        it 'does not call update_solr if not published' do
          @resource.update(publication_date: Time.now.utc.to_date.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'action_required', user: @curator)
          expect(ca).not_to receive(:update_solr)
          ca.save
        end

      end

      context :process_payment do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_status_change_notices).and_return(true)
        end

        it 'calls submit_to_stripe when published' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published', user: @curator)
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        it 'calls submit_to_stripe when embargoed' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed', user: @curator)
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe if not ready_for_payment' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(false)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'submitted', user: @curator)
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe if skip_datacite' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          allow_any_instance_of(StashEngine::Resource).to receive(:skip_datacite_update).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published', user: @curator)
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe when user is not responsible for payment' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          allow_any_instance_of(StashEngine::Identifier).to receive(:user_must_pay?).and_return(false)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed', user: @curator)
          expect(ca).to receive(:process_payment)
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

        describe 'calls proper Stash::Payments::Invoicer method' do
          let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'stripe-123', old_payment_system: true) }
          let(:res_1) { create(:resource, identifier: identifier, total_file_size: 103_807_000_000, skip_datacite_update: false) }
          let(:curator) { create(:user, role: 'curator') }
          subject { Stash::Payments::Invoicer.new(resource: res_1, curator: curator) }

          before do
            mock_salesforce!
            allow_any_instance_of(StashEngine::CurationActivity).to receive(:submit_to_datacite).and_return(true)
            allow_any_instance_of(StashEngine::CurationActivity).to receive(:update_solr).and_return(true)
            allow_any_instance_of(StashEngine::CurationActivity).to receive(:remove_peer_review).and_return(true)
          end

          context 'on first publish' do
            it 'cals #charge_user_via_invoice' do
              expect(Stash::Payments::Invoicer).to receive(:new).with(resource: res_1, curator: curator).and_return(subject)
              expect(subject).to receive(:charge_user_via_invoice).and_return(true)

              create(:curation_activity, resource: res_1, status: 'published', note: 'first publish', user: curator)
            end
          end

          context 'on second publish' do
            context 'if identifier has no last_invoiced_file_size value' do
              it 'it should not be processed by any invoicer' do
                expect(Stash::Payments::Invoicer).to receive(:new).with(resource: res_1, curator: curator).and_return(subject)
                expect(subject).to receive(:charge_user_via_invoice).and_return(true)
                create(:curation_activity, resource: res_1, status: 'published', note: 'first publish', user: curator)

                Timecop.travel(1.minute) do
                  res_2 = create(:resource, identifier: identifier, total_file_size: 104_807_000_000)
                  expect(Stash::Payments::Invoicer).not_to receive(:new)
                  expect(Stash::Payments::StripeInvoicer).not_to receive(:new)

                  create(:curation_activity, resource: res_2, status: 'published', note: 'second publish', user: curator)
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
                create(:curation_activity, resource: res_1, status: 'published', note: 'first publish', user: curator)

                Timecop.travel(1.minute) do
                  res_2 = create(:resource, identifier: identifier, total_file_size: 104_807_000_000)
                  expect(Stash::Payments::Invoicer).not_to receive(:new)
                  expect(Stash::Payments::StripeInvoicer).not_to receive(:new)

                  create(:curation_activity, resource: res_2, status: 'published', note: 'second publish', user: curator)
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

        StashEngine::CurationActivity.statuses.each_key do |status|
          if %w[published embargoed peer_review submitted withdrawn].include?(status)
            it "sends email when '#{status}'" do
              expect_any_instance_of(StashEngine::UserMailer).to receive(:status_change)
              ca = create(:curation_activity, resource: @resource, status: status)
              ca.save
            end
          else
            it "does not send email when '#{status}'" do
              expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
              ca = create(:curation_activity, resource_id: @resource.id, status: status)
              ca.save
            end
          end
        end

        it "does not send email when resource is 'submitted' a second time" do
          ca = create(:curation_activity, resource: @resource, status: 'submitted')
          ca.save
          ca2 = create(:curation_activity, resource: @resource, status: 'peer_review')
          ca2.save
          expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
          ca3 = create(:curation_activity, resource: @resource, status: 'submitted')
          ca3.save
        end

        it "does not send email when identifier is 'published' a second time" do
          ca = create(:curation_activity, resource: @resource, status: 'published')
          ca.save
          expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
          new_version = create(:resource, identifier_id: @identifier.id)
          ca2 = create(:curation_activity, resource: new_version, status: 'published')
          ca2.save
        end

        it "does not send email when 'submitted' by a curator" do
          user = create(:user, role: 'curator')
          expect_any_instance_of(StashEngine::UserMailer).not_to receive(:status_change)
          ca = create(:curation_activity, resource: @resource, status: 'submitted', user: user)
          ca.save
        end
      end

      context :email_orcid_invitations do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations).and_return(false)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation).and_return(true)
          @author = create(:author, author_first_name: 'Foo', author_last_name: 'Bar', author_email: 'foo.bar@example.edu', resource_id: @resource.id)
          # in theory stash_engine doesn't depend on datacite_engine, so mocking this out for now instead of bringing that engine in
          allow_any_instance_of(StashEngine::Author).to receive(:affiliation).and_return(
            { long_name: 'Western New Mexico University', ror_id: 'https://ror.org/00r5mr697' }.to_ostruct
          )
        end

        it 'calls email_orcid_invitations when published' do
          expect_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

        it 'does not call email_orcid_invitations to authors who already have an invitation' do
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return('fool.bar@example.edu')
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:identifier_id).and_return(@identifier.id)
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:email).and_return(@author.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

        it 'does not call email_orcid_invitations to authors who already have an ORCID registered' do
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return(@author.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca = create(:curation_activity, resource_id: @resource.id, status: 'published')
        end

      end

      context :update_publication_flags do
        it 'sets flags for embargo' do
          create(:curation_activity, status: 'embargoed', resource: @resource)
          @identifier.reload
          @resource.reload
          expect(@identifier.pub_state).to eq('embargoed')
          expect(@resource.meta_view).to eq(true)
          expect(@resource.file_view).to eq(false)
        end

        context 'changing status to published' do
          it 'sets flags for published with file changes' do
            @resource.data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
            @resource.reload
            create(:curation_activity, resource: @resource, status: 'published')

            @identifier.reload
            @resource.reload

            expect(@identifier.pub_state).to eq('published')
            expect(@resource.meta_view).to eq(true)
            expect(@resource.file_view).to eq(true)
          end

          context 'when there is another published resource' do
            it 'sets flags for published with file changes' do
              @resource.data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
              @resource.reload
              create(:curation_activity, resource: @resource, status: 'published')

              @identifier.reload
              @resource.reload

              expect(@identifier.pub_state).to eq('published')
              expect(@resource.meta_view).to eq(true)
              expect(@resource.file_view).to eq(true)

              # new version
              new_resource = create(:resource, identifier_id: @identifier.id, created_at: 4.minutes.ago)
              # @resource.data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
              # new_resource.reload
              create(:curation_activity, resource: new_resource, status: 'published')

              @identifier.reload
              new_resource.reload

              expect(@identifier.pub_state).to eq('published')
              expect(new_resource.meta_view).to eq(true)
              expect(new_resource.file_view).to eq(false)
            end
          end

          context 'when the resource is set to embargoed after publishing' do
            # set initial resource to published
            # set initial resource to embargoed => file_view = false
            # create new version
            # set to published without files changes => file_view = false
            # set initial resource to published => file_view = true
            it 'sets flags for published with file changes' do
              # set initial resource to published
              @resource.data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
              @resource.reload
              create(:curation_activity, resource: @resource, status: 'published')

              @identifier.reload
              @resource.reload

              expect(@identifier.pub_state).to eq('published')
              expect(@resource.meta_view).to eq(true)
              expect(@resource.file_view).to eq(true)
              # set initial resource to embargoed => file_view = false
              create(:curation_activity, resource: @resource, status: 'embargoed')

              # create new version
              resource_2 = create(:resource, identifier_id: @identifier.id, created_at: 4.minutes.ago)
              resource_2.reload

              # set to published without files changes => file_view = false
              create(:curation_activity, resource: resource_2, status: 'published')
              @identifier.reload
              resource_2.reload
              @resource.reload

              expect(@identifier.pub_state).to eq('published')

              expect(@resource.meta_view).to eq(true)
              expect(@resource.file_view).to eq(false)
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)

              # set initial resource to published => file_view = true
              create(:curation_activity, resource: @resource, status: 'published')
              @identifier.reload
              resource_2.reload
              @resource.reload

              expect(@identifier.pub_state).to eq('published')

              expect(@resource.meta_view).to eq(true)
              expect(@resource.file_view).to eq(true)
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)
            end
          end

          context 'when there is another published resource' do
            # set initial resource to published
            # create new version
            # set to publish without file changes => file_view = false
            # create another version
            # set to publish after adding a file => file_view = true
            # create another version
            # set to publish without file changes => file_view = false
            # create another version
            # set to publish after adding a file => file_view = true
            it 'sets flags for published with file changes' do
              # set initial resource to published
              @resource.data_files << DataFile.create(file_state: 'created', download_filename: 'fun.cat', upload_file_size: 666)
              @resource.reload
              create(:curation_activity, resource: @resource, status: 'published')

              @identifier.reload
              @resource.reload

              expect(@identifier.pub_state).to eq('published')
              expect(@resource.meta_view).to eq(true)
              expect(@resource.file_view).to eq(true)

              # create new version
              resource_2 = create(:resource, identifier_id: @identifier.id, created_at: 4.minutes.ago)
              resource_2.reload
              # set to publish without file changes => file_view = false
              create(:curation_activity, resource: resource_2, status: 'published')

              @identifier.reload
              resource_2.reload

              expect(@identifier.pub_state).to eq('published')
              expect(resource_2.meta_view).to eq(true)
              expect(resource_2.file_view).to eq(false)

              # create another version
              resource_3 = create(:resource, identifier_id: @identifier.id, created_at: 3.minutes.ago)
              resource_3.data_files << DataFile.create(file_state: 'created', download_filename: 'fun2.cat', upload_file_size: 666)
              resource_3.reload

              # set to publish after adding a file => file_view = true
              create(:curation_activity, resource: resource_3, status: 'published')

              @identifier.reload
              resource_3.reload

              expect(@identifier.pub_state).to eq('published')
              expect(resource_3.meta_view).to eq(true)
              expect(resource_3.file_view).to eq(true)

              # create another version
              resource_3 = create(:resource, identifier_id: @identifier.id, created_at: 2.minutes.ago)
              resource_3.reload
              # set to publish without file changes => file_view = false
              create(:curation_activity, resource: resource_3, status: 'published')

              @identifier.reload
              resource_3.reload

              expect(@identifier.pub_state).to eq('published')
              expect(resource_3.meta_view).to eq(true)
              expect(resource_3.file_view).to eq(false)

              # create another version
              resource_3 = create(:resource, identifier_id: @identifier.id, created_at: 1.minutes.ago)
              resource_3.data_files << DataFile.create(file_state: 'created', download_filename: 'fun3.cat', upload_file_size: 666)
              resource_3.reload
              # set to publish after adding a file => file_view = true
              create(:curation_activity, resource: resource_3, status: 'published')

              @identifier.reload
              resource_3.reload

              expect(@identifier.pub_state).to eq('published')
              expect(resource_3.meta_view).to eq(true)
              expect(resource_3.file_view).to eq(true)
            end
          end
        end

        it 'sets flags for withdrawn' do
          create(:curation_activity, resource: @resource, status: 'withdrawn')
          @identifier.reload
          @resource.reload
          expect(@identifier.pub_state).to eq('withdrawn')
          expect(@resource.meta_view).to eq(false)
          expect(@resource.file_view).to eq(false)
        end
      end

      context :peer_review_status do
        it 'disables the default peer_review setting after publication' do
          @resource.hold_for_peer_review = true
          @resource.save
          create(:curation_activity, status: 'peer_review', resource: @resource)
          create(:curation_activity, status: 'published', resource: @resource)
          @resource.reload
          expect(@resource.hold_for_peer_review?).to eq(false)
        end
      end
    end

  end
end
