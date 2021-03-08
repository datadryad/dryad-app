require 'rails_helper'
require 'support/helpers/session_helper'  # Doesn't work
require 'react/rails/test_helper'  # Doesn't work
require 'rspec'

module StashEngine
  class ResourcesController
    RSpec.describe ResourcesController, type: :request do
      include MerrittHelper
      include DatasetHelper
      include DatabaseHelper
      include Mocks::CurationActivity
      include Mocks::Datacite
      include Mocks::Repository
      include Mocks::RSolr
      include Mocks::Ror
      include Mocks::Stripe
      include Mocks::Tenant

      context 'file uploads' do
        before(:each) do
          mock_repository!
          mock_solr!
          mock_ror!
          mock_datacite!
          mock_stripe!
          mock_tenant!
          ignore_zenodo!
          neuter_curation_callbacks!
          create_basic_dataset!
          allow_any_instance_of(ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
        end
        it 'assert_react_component' do
          @resource.current_resource_state.update(resource_state: 'in_progress')
          get "/stash/resources/#{@resource.id}/upload"
          expect(response).to have_http_status(200)
          # assert_react_component 'UploadFiles'
          expect(document.body.div('data-react-class' => 'UploadFiles')).to exist

          html_doc = Nokogiri::HTML(body)
          react_component = html_doc.css("div[data-react-class='UploadFiles']")
          expect(react_component).to be_a(Nokogiri::XML::NodeSet)

          props = JSON.parse(react_component.attr('data-react-props').to_s)
          expect(props['resource_id']).to eq(@resource.id)
        end
      end
    end

  end
end
