# == Schema Information
#
# Table name: dcs_descriptions
#
#  id               :integer          not null, primary key
#  description      :text(16777215)
#  description_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  resource_id      :integer
#
# Indexes
#
#  index_dcs_descriptions_on_resource_id  (resource_id)
#
require 'rails_helper'

module StashDatacite
  describe Description do
    attr_reader :resource
    before(:each) do
      user = create(:user, email: 'lmuckenhaupt@example.edu', tenant_id: 'dataone')
      @resource = create(:resource, user: user)
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
