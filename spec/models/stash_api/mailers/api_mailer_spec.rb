require_relative '../../mailer_spec_helper'

module StashApi

  describe ApiMailer do
    include MailerSpecHelper

    let(:metadata) { {} }

    before(:each) do

      @delivery_method = ActionMailer::Base.delivery_method
      ActionMailer::Base.delivery_method = :test

      @request_host = 'stash.example.org'
      @request_port = 80

      @user = create(:user)
      @resource = create(:resource, user: @user, identifier: create(:identifier))
      @identifier = @resource.identifier

      @author1 = @resource.authors.first

      @author2 = create(:author,
                        author_first_name: @user.first_name,
                        author_last_name: @user.last_name,
                        author_email: @user.email,
                        author_orcid: @user.orcid,
                        resource_id: @resource.id)

      @author2.create_edit_code(role: 'submitter')

      allow(Rails.application.routes.url_helpers).to receive(:root_url).and_return 'https://site.root/'
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
      ActionMailer::Base.delivery_method = @delivery_method
    end

    describe '#send_submit_request' do
      it 'sends email' do
        ApiMailer.send_submit_request(@resource, metadata, @author2).deliver_now
        delivery = assert_email("[test] Submit data for \"#{@resource.title}\"")
        expect(delivery.body.to_s).to include("https://site.root/accept/#{@author2.edit_code.edit_code}")
        expect(delivery.to).to eq([@author2.author_email])
      end
    end
  end
end
