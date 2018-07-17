require 'db_spec_helper'

module StashDatacite
  describe ResourceType do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
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

    describe 'resource_type_general_mapping_obj' do
      it 'returns nil for nil' do
        expect(ResourceType.resource_type_general_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::ResourceTypeGeneral.each do |type|
          value_str = type.value
          expect(ResourceType.resource_type_general_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        ResourceType::ResourceTypesGeneralStrToFull.each_key do |resource_type_general|
          resource_type = ResourceType.create(
            resource_id: resource.id,
            resource_type: 'Conscriptio super monstruosum vitulum extraneissimum',
            resource_type_general: resource_type_general
          )
          resource_type_general_friendly = resource_type.resource_type_general_friendly
          enum_instance = Datacite::Mapping::ResourceTypeGeneral.find_by_value(resource_type_general_friendly)
          expect(resource_type.resource_type_general_mapping_obj).to be(enum_instance)
        end
      end
    end
  end
end
