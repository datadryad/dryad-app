require 'rails_helper'

module StashDatacite
  describe DataciteDate do

    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      user = create(:user,
                    email: 'lmuckenhaupt@example.edu',
                    tenant_id: 'dataone')
      @resource = create(:resource, user: user)
    end

    describe 'date_type_mapping_obj' do
      it 'returns nil for nil' do
        expect(DataciteDate.date_type_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::DateType.each do |type|
          value_str = type.value
          expect(DataciteDate.date_type_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        DataciteDate::DateTypesStrToFull.each_key do |date_type|
          date = DataciteDate.create(
            resource_id: @resource.id,
            date: 'Conscriptio super monstruosum vitulum extraneissimum',
            date_type: date_type
          )
          date_type_friendly = date.date_type_friendly
          enum_instance = Datacite::Mapping::DateType.find_by_value(date_type_friendly)
          expect(date.date_type_mapping_obj).to be(enum_instance)
        end
      end
    end

    describe 'set_date_available' do

      it 'does nothing if the resource has no publication date' do
        @resource.publication_date = nil
        @resource.save
        date_available = DataciteDate.set_date_available(resource_id: @resource.id)
        expect(date_available).to be_nil
        expect(@resource.datacite_dates).to be_empty
      end

      it 'creates an "available" date based on the publication date' do
        @resource.publication_date = (Date.today + 1.month).to_s
        @resource.save
        pub_date = @resource.publication_date

        date_available = DataciteDate.set_date_available(resource_id: @resource.id)
        expect(@resource.datacite_dates.first).to eq(date_available)
        expect(date_available.date).to eq(pub_date.utc.iso8601)
        expect(date_available.date_type).to eq('available')
      end

      it 'updates an existing "available" date when the publication date changes' do
        @resource.publication_date = (Date.today + 1.month).to_s
        @resource.save
        date_available = DataciteDate.set_date_available(resource_id: @resource.id)

        new_date = Time.utc(2017, 8, 14)
        @resource.publication_date = new_date
        @resource.save

        DataciteDate.set_date_available(resource_id: @resource.id)

        date_available.reload
        expect(date_available.date).to eq(new_date.utc.iso8601)
      end
    end
  end
end
