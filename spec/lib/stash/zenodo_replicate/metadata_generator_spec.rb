# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'
require 'http'
require 'fileutils'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe MetadataGenerator do

      before(:each) do
        @resource = create(:resource)
        @mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource)
        create(:description, description_type: 'other', resource_id: @resource.id)
        create(:description, description_type: 'methods', resource_id: @resource.id)
      end

      it 'has doi output' do
        expect(@mg.doi).to eq("https://doi.org/#{@resource.identifier.identifier}")
      end

      it 'has upload_type output' do
        create(:resource_type, resource_id: @resource.id)
        expect(@mg.upload_type).to eq(@resource.resource_type.resource_type_general)
      end

      it 'has publication_date output' do
        expect(@mg.publication_date).to eq(@resource&.publication_date&.iso8601)
      end

      it 'has title output' do
        expect(@mg.title).to eq(@resource.title)
      end

      it 'has creators output' do
        cr = @mg.creators.first
        au = @resource.authors.first
        expect(cr[:orcid]).to eq(au.author_orcid)
        expect(cr[:name]).to eq("#{au.author_last_name}, #{au.author_first_name}")
        expect(cr[:affiliation]).to eq(au.affiliation.long_name)
      end

      it 'has description output' do
        expect(@mg.description).to eq(@resource.descriptions.where(description_type: 'abstract').first.description)
      end

      it 'has access_right output' do
        expect(@mg.access_right).to eq('open')
      end

      it 'has license output' do
        create(:right, resource_id: @resource.id)
        expect(@mg.license).to eq('cc-zero')
      end

      it 'has keywords output' do
        s = create(:subject)
        @resource.subjects << s
        expect(@mg.keywords.first).to eq(@resource.subjects.first.subject)
      end

      it 'has notes output' do
        expect(@mg.notes).to eq(@resource.descriptions.where(description_type: 'other').first.description)
      end

      it 'has related_identifiers output for itself' do
        expect(@mg.related_identifiers).to eq([{ relation: 'isIdenticalTo',
                                                 identifier: "https://doi.org/#{@resource.identifier.identifier}" }])
      end

      it 'has method output' do
        expect(@mg.method).to eq(@resource.descriptions.where(description_type: 'methods').first.description)
      end
    end
  end
end
