require 'rails_helper'
require 'uri'
require_relative '../stash_api/helpers'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AuthorsController, type: :request do

    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      @user = create(:user, role: 'user')
      @resource = create(:resource, user_id: @user.id)
      @authors = Array.new(7) { |_i| create(:author, resource: @resource) }
      allow_any_instance_of(AuthorsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe 'reorder' do
      it 'detects if not all author ids are for same resource' do
        @resource2 = create(:resource, user_id: @user.id)
        @bad_author = create(:author, resource: @resource2)
        update_info = (@authors + [@bad_author]).map { |author| [author.id.to_s, author.author_order] }.to_h

        response_code = patch '/stash_datacite/authors/reorder',
                              params: update_info,
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(400) # gives 400, bad request
      end

      it 'detects if user not authorized to modify this resource' do
        @user2 = create(:user, role: 'user')
        @resource2 = create(:resource, user_id: @user2.id)
        @authors2 = Array.new(7) { |_i| create(:author, resource: @resource2) }
        update_info = @authors2.map { |author| [author.id.to_s, author.author_order] }.to_h

        response_code = patch '/stash_datacite/authors/reorder',
                              params: update_info,
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(403) # no permission to modify these
      end

      it 'updates the author order to the order given' do
        update_info = @authors.map { |author| {  id: author.id, order: author.author_order } }.shuffle
        update_info = update_info.each_with_index.map do |author, idx|
          [author[:id].to_s, idx]
        end.to_h

        response_code = patch '/stash_datacite/authors/reorder',
                              params: update_info,
                              headers: default_json_headers,
                              as: :json

        expect(response_code).to eq(200)

        ret_json = JSON.parse(body)

        update_info.each_with_index do |item, idx|
          expect(item.first.to_i).to eq(ret_json[idx]['id'])
          expect(item.second).to eq(ret_json[idx]['author_order'])
        end
      end
    end
  end
end
