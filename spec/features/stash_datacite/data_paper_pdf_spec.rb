require 'rails_helper'

RSpec.feature 'DataPaperPdf', type: :feature do

  include Mocks::CurationActivity
  include Mocks::Tenant

  context :data_paper do
    before(:each) do
      neuter_curation_callbacks!
      mock_tenant!

      @resource = create(:resource, user: create(:user, tenant_id: 'dryad'), meta_view: true, file_view: true,
                                    identifier: create(:identifier, pub_state: 'published'))
      create(:publication_year, resource: @resource)
      create(:curation_activity_no_callbacks, :published, resource: @resource)

      create(:curation_activity, resource: @resource, status: 'in_progress')
      create(:curation_activity, resource: @resource, status: 'curation')
      create(:curation_activity, resource: @resource, status: 'published')

      rs = create(:resource_state, resource_id: @resource.id, resource_state: 'submitted')
      @resource.update(current_resource_state_id: rs.id)
      @resource.reload
    end

    it 'generates the pdf' do
      visit stash_url_helpers.data_paper_path(@resource.identifier_str, debug: true)
      expect(page).to have_content(@resource.title)
    end
  end

end
