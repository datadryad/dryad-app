module StashEngine
  RSpec.describe ResourcesController, type: :request do
    include DatabaseHelper

    context 'file uploads' do
      before(:each) do
        create_basic_dataset!
        allow_any_instance_of(ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
      end

      it 'assert_react_root_component' do
        @resource.current_resource_state.update(resource_state: 'in_progress')
        get "/stash/resources/#{@resource.id}/upload"

        assert_react_component "UploadFiles" do |props|
          assert_equal @resource.id, props[:resource_id]
        end
      end
    end

  end
end
