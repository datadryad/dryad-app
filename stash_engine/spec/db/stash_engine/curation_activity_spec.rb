require 'db_spec_helper'

module StashEngine
  describe CurationActivity do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
      @resource = StashEngine::Resource.create(identifier_id: @identifier.id)
      # reload so that it picks up any associated models that are initialized
      # (e.g. CurationActivity and ResourceState)
      @resource.reload
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
        ca2 = CurationActivity.create(resource_id: @resource.id, status: 'peer_review')
        expect(CurationActivity.latest(@resource)).to eql(ca2)
      end
    end

    context :readable_status do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'class method allows conversion of status to humanized status' do
        expect(CurationActivity.readable_status('submitted')).to eql('Submitted')
      end

      it 'returns a readable version of :peer_review' do
        @ca.peer_review!
        expect(@ca.readable_status).to eql('Private for Peer Review')
      end

      it 'returns a readable version of :action_required' do
        @ca.action_required!
        expect(@ca.readable_status).to eql('Author Action Required')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize.split.map(&:capitalize).join(' '))
          end
        end
      end
    end

    context :callbacks do

      before(:each) do
        allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
        allow_any_instance_of(Stash::Doi::IdGen).to receive(:make_instance).and_return(true)
        allow_any_instance_of(Stash::Doi::IdGen).to receive(:update_identifier_metadata).and_return(true)
        allow_any_instance_of(Stash::Payments::Invoicer).to receive(:new).and_return(true)
        allow_any_instance_of(Stash::Payments::Invoicer).to receive(:charge_via_invoice).and_return(true)
      end

      it 'updates the resources.current_curation_activity_id when creating a new record' do
        ca = CurationActivity.create(resource_id: @resource.id)
        expect(@resource.reload.current_curation_activity_id).to eql(ca.id)
      end

      it 'removes the resources.current_curation_activity_id when the record is deleted and no prior curation activity exists' do
        @resource.current_curation_activity.destroy
        expect(@resource.reload.current_curation_activity_id).to eql(nil)
      end

      it 'updates the resources.current_curation_activity_id to the prior curation activity when the record is removed' do
        original = @resource.current_curation_activity_id
        ca = CurationActivity.create(resource_id: @resource.id, status: 'submitted')

        ca.destroy
        expect(@resource.reload.current_curation_activity_id).to eql(original)
      end

      context :update_solr do

        it 'calls update_solr when published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).to receive(:update_solr)
          ca.save
        end

        it 'calls update_solr when embargoed' do
          @resource.update(publication_date: (Date.today + 1.day).to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:update_solr)
          ca.save
        end

        it 'does not call update_solr if not published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'action_required')
          expect(ca).not_to receive(:update_solr)
          ca.save
        end

      end

      context :submit_to_datacite do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_author).and_return(true)
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:orcid_invitation).and_return(true)
        end

        it 'calls submit_to_datacite when published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).to receive(:submit_to_datacite)
          ca.save
        end

        it 'calls submit_to_datacite when embargoed' do
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:submit_to_datacite)
          ca.save
        end

        it 'does not call submit_to_datacite if not published' do
          @resource.update(publication_date: Date.today.to_s)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'action_required')
          expect(ca).not_to receive(:submit_to_datacite)
          ca.save
        end

      end

      context :submit_to_stripe do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_author).and_return(true)
        end

        it 'calls submit_to_stripe when published' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        it 'calls submit_to_stripe when embargoed' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(true)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'embargoed')
          expect(ca).to receive(:submit_to_stripe)
          ca.save
        end

        it 'does not call submit_to_stripe if not ready_for_payment' do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:ready_for_payment?).and_return(false)
          ca = CurationActivity.new(resource_id: @resource.id, status: 'submitted')
          expect(ca).not_to receive(:submit_to_stripe)
          ca.save
        end

      end

      context :email_author do

        before(:each) do
          allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
        end

        StashEngine::CurationActivity.statuses.each do |status|

          if %w[published embargoed].include?(status)
            it "calls email_author when '#{status}'" do
              allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_author?).and_return(false)
              ca = CurationActivity.new(resource_id: @resource.id, status: status)
              expect(ca).to receive(:email_author)
              ca.save
            end
          else
            it "does not call email_author when '#{status}'" do
              allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_author?).and_return(false)
              ca = CurationActivity.new(resource_id: @resource.id, status: status)
              expect(ca).not_to receive(:email_author)
              ca.save
            end
          end

        end

      end

      context :email_orcid_invitations do

        before(:each) do
          allow_any_instance_of(StashEngine::CurationActivity).to receive(:email_orcid_invitations).and_return(false)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:status_change).and_return(true)
          allow_any_instance_of(StashEngine::UserMailer).to receive(:orcid_invitation).and_return(true)
          @user = Author.create(author_first_name: 'Foo', author_last_name: 'Bar', author_email: 'foo.bar@example.edu', resource_id: @resource.id)
          @ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
        end

        it 'calls email_orcid_invitations when published' do
          expect(@ca).to receive(:email_orcid_invitations)
          @ca.save
        end

        it 'does not call email_orcid_invitations to authors who already have an invitation' do
          allow_any_instance_of(StashEngine::User).to receive(:orcid_id).and_return(nil)
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return('fool.bar@example.edu')
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:identifier_id).and_return(@identifier.id)
          allow_any_instance_of(StashEngine::OrcidInvitation).to receive(:email).and_return(@user.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca.save
        end

        it 'does not call email_orcid_invitations to authors who already have an ORCID registered' do
          allow_any_instance_of(StashEngine::User).to receive(:orcid_id).and_return('12345')
          allow_any_instance_of(StashEngine::User).to receive(:email).and_return(@user.author_email)
          expect(UserMailer).not_to receive(:orcid_invitation)
          @ca.save
        end

      end

    end

  end
end
