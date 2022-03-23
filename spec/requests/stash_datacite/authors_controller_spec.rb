require 'rails_helper'
require 'uri'
require_relative '../stash_api/helpers'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashDatacite
  RSpec.describe AuthorsController, type: :request do

    before(:each) do
      @user = create(:user, role: 'user')
      @resource = create(:resource, user_id: @user.id)
      @authors = Array.new(7) { |_i| create(:author, resource: @resource) }
      allow_any_instance_of(AuthorsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe 'reorder' do
      it 'detects if not all author ids are for same resource' do
        @resource2 = create(:resource, user_id: @user.id)
        @bad_author = create(:author, resource: @resource2)
        update_info = (@authors + [@bad_author]).map{|author| {id: author.id, order: author.author_order} }

        response_code = patch "/stash_datacite/authors/reorder",
                             params: update_info.to_json,
                             headers: default_json_headers

        expect(response_code).to eq(400) # gives 400, bad request
      end

      it "detects if user not authorized to modify this resource" do
        @user2 = create(:user, role: 'user')
        @resource2 = create(:resource, user_id: @user2.id)
        @authors2 = Array.new(7) { |_i| create(:author, resource: @resource2) }
        update_info = @authors2.map{|author| {id: author.id, order: author.author_order} }

        response_code = patch "/stash_datacite/authors/reorder",
                              params: update_info.to_json,
                              headers: default_json_headers

        expect(response_code).to eq(403) # no permission to modify these
      end

      it "updates the author order to the order given" do
        update_info = @authors.map{|author| {id: author.id, order: author.author_order} }.shuffle
        update_info.map!{|author, idx| {id: author[:id], order: idx} }

        response_code = patch "/stash_datacite/authors/reorder",
                              params: update_info.to_json,
                              headers: default_json_headers

        byebug
      end
    end
  end
end
