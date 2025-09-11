module StashEngine

  RSpec.describe ResourcesController, type: :request do
    describe 'display_readme' do
      let(:user) { create(:user) }
      let!(:resource) { create(:resource) }
      let!(:readme) do
        create(:description, resource: resource, description_type: 'technicalinfo', description: File.read('spec/fixtures/README_filelist.md'))
      end

      before do
        allow_any_instance_of(ResourcesController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
      end

      it 'displays the readme' do
        get "/resources/#{resource.id}/display_readme"
        expect(body).to include('<h2>README: A Test README to check outputs</h2>')
      end

      it 'displays the table' do
        get "/resources/#{resource.id}/display_readme"
        expect(body).to include('<div class="table-wrapper" role="region" tabindex="0" aria-label="Table"><table>')
      end

      it 'displays superscript and subscript' do
        get "/resources/#{resource.id}/display_readme"
        expect(body).to include('<sup>superscript</sup> and <sub>subscript</sub>')
      end
    end

  end
end
