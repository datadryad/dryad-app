require 'rails_helper'

module StashEngine

  RSpec.describe RorOrg, type: :model do

    before(:each) do
      @ror_org = create(:ror_org)
      @isni = "1234 #{Faker::Number.number(digits: 4)} #{Faker::Number.number(digits: 4)} #{Faker::Number.number(digits: 4)}"
      @ror_org.update(isni_ids: [@isni])
    end

    describe 'find_by_ror_name' do
      it 'returns empty' do
        result = RorOrg.find_by_ror_name('NOT the @ror_org name')
        expect(result.size).to eql(0)
      end

      it 'handles a precise query' do
        result = RorOrg.find_by_ror_name(@ror_org.name)
        expect(result.size).to eql(1)
        expect(result.first[:name]).to eql(@ror_org.name)
        expect(result.first[:id]).to eql(@ror_org.ror_id)
      end

      it 'handles a broader query with several results' do
        create(:ror_org, name: "#{@ror_org.name} subsection")
        create(:ror_org, name: "#{@ror_org.name} department")

        result = RorOrg.find_by_ror_name(@ror_org.name)
        expect(result.size).to eql(3)
        expect(result.first[:name]).to include(@ror_org.name)
        expect(result.second[:name]).to include(@ror_org.name)
        expect(result.third[:name]).to include(@ror_org.name)
      end
    end

    describe 'find_first_by_ror_name' do
      it 'returns none' do
        result = RorOrg.find_first_by_ror_name('NOT a ror name')
        expect(result).to be(nil)
      end

      it 'returns when exact name match' do
        result = RorOrg.find_first_by_ror_name(@ror_org.name)
        expect(result).to eql(@ror_org)
      end

      it 'returns original one when exact name match' do
        create(:ror_org, name: @ror_org.name)
        result = RorOrg.find_first_by_ror_name(@ror_org.name)
        expect(result).to eql(@ror_org)
      end
    end

    describe 'find_by_ror_id' do
      it 'returns none' do
        result = RorOrg.find_by_ror_id('NOT a ror id')
        expect(result).to be(nil)
      end

      it 'returns when exact match' do
        result = RorOrg.find_by_ror_id(@ror_org.ror_id)
        expect(result).to eql(@ror_org)
      end
    end

    describe 'find_by_isni_id' do
      it 'errors with incorrectly-formatted ISNI' do
        expect { RorOrg.find_by_isni_id('NOT an ISNI') }.to raise_error
      end

      it 'returns none when the ISNIs do not match' do
        result = RorOrg.find_by_isni_id('0000 0000 0000 0000')
        expect(result).to be(nil)
      end

      it 'returns when exact match' do
        result = RorOrg.find_by_isni_id(@isni)
        expect(result).to eql(@ror_org)
      end

      it 'returns when spaces are removed from ISNI' do
        result = RorOrg.find_by_isni_id(@isni.gsub(/\s+/, ''))
        expect(result).to eql(@ror_org)
      end

    end

  end
end
