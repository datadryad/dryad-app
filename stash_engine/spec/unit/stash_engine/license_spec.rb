require 'spec_helper'

module StashEngine
  describe License do
    attr_reader :uris_by_id

    before(:all) do
      @uris_by_id = {
        cc0: 'https://creativecommons.org/publicdomain/zero/1.0/',
        cc_by: 'https://creativecommons.org/licenses/by/4.0/'
      }.freeze
    end

    describe '#by_id' do
      it 'finds all the licenses' do
        %w[cc0 cc_by].each do |id|
          lic = License.by_id(id)
          expect(lic).to be_a(Hash)
          expected_uri = uris_by_id[id.to_sym]
          expect(lic[:uri]).to eq(expected_uri)
        end
      end
    end

    describe '#find' do
      it 'finds all the licenses' do
        %w[cc0 cc_by].each do |id|
          lic = License.find(id)
          expect(lic).to be_a(Hash)
          expected_uri = uris_by_id[id.to_sym]
          expect(lic[:uri]).to eq(expected_uri)
        end
      end
    end

    describe '#by_uri' do
      it 'finds all the licenses' do
        uris_by_id.each_value do |uri|
          lic = License.by_uri(uri)
          expect(lic).to be_a(Hash)
          expect(lic[:uri]).to eq(uri)
        end
      end
    end
  end
end
