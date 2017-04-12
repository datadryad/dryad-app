require 'db_spec_helper'

module StashDatacite
  describe ResourceType do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        uid: 'lmuckenhaupt-example@example.edu',
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe 'resource_type_general_ui' do
      it 'returns the UI value' do
        ResourceType::ResourceTypesGeneralLimited.each do |ui_value, db_value|
          resource_type = ResourceType.create(resource_id: resource.id, resource_type_general: db_value)
          expect(resource_type.resource_type_general_ui).to eq(ui_value.to_s)
        end
      end
    end
  end
end
