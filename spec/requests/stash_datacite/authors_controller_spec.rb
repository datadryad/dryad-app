require 'rails_helper'
require 'uri'
require_relative '../stash_api/helpers'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AuthorsController, type: :request do

    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      @user = create(:user)
      @resource = create(:resource, user_id: @user.id)
      @authors = Array.new(7) { |_i| create(:author, resource: @resource) }
      allow_any_instance_of(AuthorsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe '#reorder' do
      it 'detects if not all author ids are for same resource' do
        @resource2 = create(:resource, user_id: @user.id)
        @bad_author = create(:author, resource: @resource2)
        update_info = (@authors + [@bad_author]).to_h { |author| [author.id.to_s, author.author_order] }

        code = patch '/stash_datacite/authors/reorder', params: update_info, headers: default_json_headers, as: :json

        expect(code).to eq(400) # gives 400, bad request
      end

      it 'detects if user not authorized to modify this resource' do
        @user2 = create(:user)
        @resource2 = create(:resource, user_id: @user2.id)
        @authors2 = Array.new(7) { |_i| create(:author, resource: @resource2) }
        update_info = @authors2.to_h { |author| [author.id.to_s, author.author_order] }

        code = patch '/stash_datacite/authors/reorder', params: update_info, headers: default_json_headers, as: :json

        expect(code).to eq(403) # no permission to modify these
      end

      it 'updates the author order to the order given' do
        update_info = @authors.map { |author| { id: author.id, order: author.author_order } }.shuffle
        update_info = update_info.each_with_index.to_h do |author, idx|
          [author[:id].to_s, idx]
        end

        code = patch '/stash_datacite/authors/reorder', params: update_info, headers: default_json_headers, as: :json

        expect(code).to eq(200)

        ret_json = JSON.parse(body)

        update_info.each_with_index do |item, idx|
          expect(item.first.to_i).to eq(ret_json[idx]['id'])
          expect(item.second).to eq(ret_json[idx]['author_order'])
        end
      end
    end

    describe '#update' do
      let(:resource) { create(:resource, user_id: @user.id) }
      let(:author) { create(:author, resource_id: resource.id) }
      let!(:affil_1) { create(:affiliation, ror_id: 'https://ror.org/ror1') }
      let!(:affil_2) { create(:affiliation, ror_id: 'https://ror.org/ror2') }
      let!(:affil_3) { create(:affiliation, ror_id: nil) }

      let(:params) do
        {
          author: {
            id: author.id,
            author_first_name: 'Test',
            author_last_nam: 'Author',
            author_org_name: nil,
            author_email: 'test@email.org',
            resource_id: resource.id,
            affiliations: [
              { id: affil_1.id, short_name: nil, long_name: affil_1.long_name, abbreviation: nil, ror_id: affil_1.ror_id },
              { id: affil_1.id, short_name: nil, long_name: affil_1.long_name, abbreviation: nil, ror_id: affil_1.ror_id },
              { id: affil_2.id, short_name: nil, long_name: affil_2.long_name, abbreviation: nil, ror_id: affil_2.ror_id },
              { id: affil_3, short_name: nil, long_name: affil_3.long_name, abbreviation: nil, ror_id: affil_3.ror_id },
              { long_name: 'Manual entered', ror_id: nil },
              { long_name: 'Manual entered', ror_id: nil }
            ]
          }
        }
      end

      before do
        author.affiliations = [affil_1]
      end

      subject { patch('/stash_datacite/authors/update', params: params, headers: default_json_headers, as: :json) }

      it 'successfully saves multiple affiliations without ror' do
        expect(subject).to eq(200)
        author.reload

        expect(author.affiliations.count).to eq(4)
        expect(author.affiliations.ids).to include(affil_1.id, affil_2.id, affil_3.id)
        # does not save duplicates
        expect(author.affiliations.map(&:long_name)).to contain_exactly(affil_1.long_name, affil_2.long_name, affil_3.long_name, 'Manual entered')
        # saves multiple affiliations without rorID
        expect(author.affiliations.where(ror_id: nil).count).to eq(2)
      end
    end
  end
end
