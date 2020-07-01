require 'rails_helper'

module StashDatacite
  describe RelatedIdentifier do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#to_s' do
      it 'provides a reader-friendly description' do
        RelatedIdentifier::RelationTypesLimited.each_value do |rel_type|
          related_doi_value = "10.5555/#{Time.now.nsec}"
          rel_id = RelatedIdentifier.create(
            resource_id: resource.id,
            relation_type: rel_type,
            related_identifier_type: 'doi',
            related_identifier: related_doi_value
          )
          rel_type_friendly = RelatedIdentifier::RelationTypesStrToFull[rel_type]
          rel_type_english = rel_type_friendly.underscore.tr('_', ' ').downcase

          str = rel_id.to_s
          expect(str).to include(rel_type_english)
          expect(str).to include('DOI')
          expect(str).to include(related_doi_value)
        end
      end
    end

    describe 'relation_type_mapping_obj' do
      it 'returns nil for nil' do
        expect(RelatedIdentifier.relation_type_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::RelationType.each do |type|
          value_str = type.value
          expect(RelatedIdentifier.relation_type_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        RelatedIdentifier::RelationTypesLimited.each_value do |rel_type|
          related_doi_value = "10.5555/#{Time.now.nsec}"
          rel_id = RelatedIdentifier.create(
            resource_id: resource.id,
            relation_type: rel_type,
            related_identifier_type: 'doi',
            related_identifier: related_doi_value
          )
          rel_type_friendly = rel_id.relation_type_friendly
          enum_instance = Datacite::Mapping::RelationType.find_by_value(rel_type_friendly)
          expect(rel_id.relation_type_mapping_obj).to be(enum_instance)
        end
      end
    end

    describe 'related_identifier_type_mapping_obj' do
      it 'returns nil for nil' do
        expect(RelatedIdentifier.related_identifier_type_mapping_obj(nil)).to be_nil
      end
      it 'maps type values to enum instances' do
        Datacite::Mapping::RelatedIdentifierType.each do |type|
          value_str = type.value
          expect(RelatedIdentifier.related_identifier_type_mapping_obj(value_str)).to be(type)
        end
      end
      it 'returns the enum instance for a model object' do
        RelatedIdentifier::RelatedIdentifierTypesLimited.each_value do |rel_type|
          related_doi_value = "10.5555/#{Time.now.nsec}"
          rel_id = RelatedIdentifier.create(
            resource_id: resource.id,
            related_identifier_type: rel_type,
            related_identifier: related_doi_value
          )
          rel_id_type_friendly = rel_id.related_identifier_type_friendly
          enum_instance = Datacite::Mapping::RelatedIdentifierType.find_by_value(rel_id_type_friendly)
          expect(rel_id.related_identifier_type_mapping_obj).to be(enum_instance)
        end
      end
    end

    describe 'self.add_zenodo_relation' do
      it 'adds a record to the database for a zenodo doi' do
        test_doi = "#{rand.to_s[2..6]}/zenodo#{rand.to_s[2.11]}"
        r = StashDatacite::RelatedIdentifier.add_zenodo_relation(resource_id: @resource.id, doi: test_doi)
        expect(r.related_identifier).to eq(test_doi)
        expect(r.relation_type).to eq('issupplementto')
      end

      it "doesn't add the zenodo issupplement doi multiple times" do
        test_doi = "#{rand.to_s[2..6]}/zenodo#{rand.to_s[2.11]}"
        StashDatacite::RelatedIdentifier.add_zenodo_relation(resource_id: @resource.id, doi: test_doi)
        StashDatacite::RelatedIdentifier.add_zenodo_relation(resource_id: @resource.id, doi: test_doi)
        expect(@resource.related_identifiers.count).to eq(1)
        expect(@resource.related_identifiers.first.related_identifier).to eq(test_doi)
      end
    end
  end
end
