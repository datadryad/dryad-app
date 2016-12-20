require 'db_spec_helper'

module StashDatacite
  module Resource
    describe Completions do
      REQUIRED_FIELDS = ['title', 'creator affiliation', 'resource type', 'creator name', 'abstract'].freeze
      REQUIRED_COUNT = REQUIRED_FIELDS.size

      OPTIONAL_FIELDS = ['date', 'keywords', 'methods', 'related identifiers'].freeze
      OPTIONAL_COUNT = OPTIONAL_FIELDS.size

      attr_reader :user
      attr_reader :stash_wrapper
      attr_reader :dcs_resource

      attr_reader :resource
      attr_reader :completions
      before(:all) do
        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )

        dc3_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(dc3_xml)
        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        @stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)
      end

      before(:each) do
        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

        @completions = Completions.new(resource)
      end

      describe '#title' do
        it 'passes for resources with titles' do
          expect(completions.title).to be_truthy
        end

        it 'fails if title is missing' do
          resource.titles.each(&:destroy)
          expect(completions.title).to be_falsey
        end
      end

      describe('#institution') do
        it 'passes for resources with creator affiliations' do
          expect(completions.institution).to be_truthy
        end

        it 'fails if creator affiliation is missing' do
          resource.creators.flat_map(&:affiliations).each(&:destroy)
          expect(completions.institution).to be_falsey
        end
      end

      describe('#data_type') do
        it 'passes for resources with a type' do
          expect(completions.data_type).to be_truthy
        end
        it 'fails if type is missing' do
          resource.resource_type.destroy
          resource.reload # ActiveRecord is not smart enough to check 'destroyed' flag
          expect(completions.data_type).to be_falsey
        end
      end

      describe('#creator_name') do
        it 'passes if all creators have first names' do
          expect(completions.creator_name).to be_truthy
        end
        it 'fails if some creators don\'t have first names' do
          creator = resource.creators.first
          creator.creator_first_name = nil
          creator.save
          expect(completions.creator_name).to be_falsey
        end
        it 'fails if creator is missing' do
          resource.creators.each(&:destroy)
          expect(completions.creator_name).to be_falsey
        end
      end

      describe('#creator_affiliation') do
        it 'fails if creator is missing' do
          resource.creators.each(&:destroy)
          expect(completions.creator_affiliation).to be_falsey
        end

        it 'passes for resources with creator affiliations' do
          expect(completions.creator_affiliation).to be_truthy
        end

        it 'fails if creator affiliation is missing' do
          resource.creators.flat_map(&:affiliations).each(&:destroy)
          expect(completions.creator_affiliation).to be_falsey
        end
      end

      describe('#abstract') do
        it 'passes for resources with abstracts' do
          expect(completions.abstract).to be_truthy
        end
        it 'passes for resources with no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no abstracts' do
          resource.descriptions.where(description_type: 'abstract').each(&:destroy)
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no non-nil abstracts' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = nil
            abstract.save
          end
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no non-blank abstracts' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = ''
            abstract.save
          end
          expect(completions.abstract).to be_falsey
        end
      end

      describe('#required_total') do
        it "counts all of: #{REQUIRED_FIELDS.join(', ')}" do
          expect(completions.required_total).to eq(REQUIRED_COUNT)
        end
      end

      describe('#required_completed') do
        it "returns a full count for resources with all of: #{REQUIRED_FIELDS.join(', ')}" do
          expect(completions.required_completed).to eq(REQUIRED_COUNT)
        end

        it 'counts if title is missing' do
          resource.titles.each(&:destroy)
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'counts if affiliation is missing' do
          resource.creators.flat_map(&:affiliations).each(&:destroy)
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if resource type is missing' do
          resource.resource_type.destroy
          resource.reload # ActiveRecord is not smart enough to check 'destroyed' flag
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'double-counts (creator and name) if creator is missing' do
          resource.creators.each(&:destroy)
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 2)
        end

        it 'counts if creator name is missing' do
          creator = resource.creators.first
          creator.creator_first_name = nil
          creator.save
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'counts if description is missing' do
          resource.descriptions.each(&:destroy)
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract is missing' do
          resource.descriptions.where(description_type: 'abstract').each(&:destroy)
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract text is nil' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = nil
            abstract.save
          end
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract text is blank' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = ''
            abstract.save
          end
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end
      end

      describe('#date') do
        it 'passes if resource has a date' do
          expect(completions.date).to be_truthy
        end
        it 'fails if resource has no date' do
          resource.datacite_dates.each(&:destroy)
          expect(completions.date).to be_falsey
        end
      end

      describe('#keyword') do
        it 'passes if resource has subjects' do
          expect(completions.keyword).to be_truthy
        end
        it 'fails if resource has no subjects' do
          resource.subjects.clear
          expect(completions.keyword).to be_falsey
        end
        it 'fails if resource has no non-nil subjects' do
          resource.subjects.each do |subj|
            subj.subject = nil
            subj.save
          end
          expect(completions.keyword).to be_falsey
        end
        it 'fails if resource has no non-blank subjects' do
          resource.subjects.each do |subj|
            subj.subject = ''
            subj.save
          end
          expect(completions.keyword).to be_falsey
        end
      end

      describe('#method') do
        before(:each) do
          Description.create(
            description: 'some methods',
            description_type: 'methods',
            resource_id: resource.id
          )
        end
        it 'passes for resources with methods' do
          expect(completions.method).to be_truthy
        end
        it 'fails for resources with no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no methods' do
          resource.descriptions.where(description_type: 'methods').each(&:destroy)
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no non-nil methodss' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = nil
            methods.save
          end
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no non-blank methodss' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = ''
            methods.save
          end
          expect(completions.method).to be_falsey
        end
      end

      describe '#citation' do
        it 'passes if resource has related identifiers' do
          expect(completions.citation).to be_truthy
        end
        it 'fails if resource has no related identifiers' do
          resource.related_identifiers.each(&:destroy)
          expect(completions.citation).to be_falsey
        end
        it 'fails if resource has no non-nil related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = nil
            rel_ident.save
          end
          expect(completions.citation).to be_falsey
        end
        it 'fails if resource has no non-empty related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = ''
            rel_ident.save
          end
          expect(completions.citation).to be_falsey
        end
      end

      describe('#optional_total') do
        it "counts all of: #{OPTIONAL_FIELDS.join(', ')}" do
          expect(completions.optional_total).to eq(OPTIONAL_COUNT)
        end
      end

      describe('#optional_completed') do
        before(:each) do
          Description.create(
            description: 'some methods',
            description_type: 'methods',
            resource_id: resource.id
          )
        end

        it "returns a full count for resources with all of: #{OPTIONAL_FIELDS.join(', ')}" do
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT)
        end

        it 'counts if date is missing' do
          resource.datacite_dates.each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end

        it 'counts if keywords are missing' do
          resource.subjects.clear
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end

        it 'counts if resource has no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no methods' do
          resource.descriptions.where(description_type: 'methods').each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no non-nil methodss' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = nil
            methods.save
          end
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no non-blank methodss' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = ''
            methods.save
          end
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
      end
    end
  end
end
