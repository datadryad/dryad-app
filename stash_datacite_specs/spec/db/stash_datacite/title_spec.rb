require 'db_spec_helper'

module StashDatacite
  describe Title do
    attr_reader :resource
    attr_reader :primary_title
    attr_reader :another_title
    before(:each) do
      user = StashEngine::User.create(
        uid: 'lmuckenhaupt-example@example.edu',
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
      @primary_title = Title.create(
        resource_id: resource.id,
        title: 'An account of a very odd Monstrous Calf'
      )
      @another_title = Title.create(
        resource_id: resource.id,
        title: 'Conscriptio super monstruosum vitulum extraneissimum',
        title_type: 'translatedtitle'
      )
    end

    describe :title do
      it 'returns the title' do
        expect(primary_title.title).to eq('An account of a very odd Monstrous Calf')
        expect(another_title.title).to eq('Conscriptio super monstruosum vitulum extraneissimum')
      end
    end

    describe :title_type do
      it 'returns the type' do
        expect(primary_title.title_type).to be_nil
        expect(another_title.title_type).to eq('translatedtitle')
      end
    end

    describe 'Resource.primary_title' do
      it 'returns the primary title' do
        expect(resource.primary_title).to eq(primary_title.title)
      end
    end

    describe 'title_type_mapping_obj' do
      it 'returns nil for nil' do
        expect(Title.title_type_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::TitleType.each do |type|
          value_str = type.value
          expect(Title.title_type_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        Title::TitleTypesStrToFull.keys.each do |title_type|
          title = Title.create(
            resource_id: resource.id,
            title: 'Conscriptio super monstruosum vitulum extraneissimum',
            title_type: title_type
          )
          title_type_friendly = title.title_type_friendly
          enum_instance = Datacite::Mapping::TitleType.find_by_value(title_type_friendly)
          expect(title.title_type_mapping_obj).to be(enum_instance)
        end
      end
    end
  end
end
