require 'db_spec_helper'

module StashDatacite
  describe Description do
    attr_reader :resource
    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe 'description_type_mapping_obj' do
      it 'returns nil for nil' do
        expect(Description.description_type_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::DescriptionType.each do |type|
          value_str = type.value
          expect(Description.description_type_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        Description::DescriptionTypesStrToFull.each_key do |description_type|
          description = Description.create(
            resource_id: resource.id,
            description: 'Conscriptio super monstruosum vitulum extraneissimum',
            description_type: description_type
          )
          description_type_friendly = description.description_type_friendly
          enum_instance = Datacite::Mapping::DescriptionType.find_by_value(description_type_friendly)
          expect(description.description_type_mapping_obj).to be(enum_instance)
        end
      end
    end
  end
end
