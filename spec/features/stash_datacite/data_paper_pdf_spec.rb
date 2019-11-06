require 'rails_helper'

RSpec.feature 'DataPaperPdf', type: :feature do

  context :data_paper do
    before(:each) do
      @resource = create(:resource, user: create(:user, tenant_id: 'dryad'), identifier: create(:identifier))
      create(:publication_year, resource: @resource)
      create(:curation_activity_no_callbacks, :published, resource: @resource)
    end

    it 'generates the pdf' do
      visit stash_url_helpers.data_paper_path(@resource.identifier_str, debug: true)
      expect(page).to have_content(@resource.title)
    end
  end

end
