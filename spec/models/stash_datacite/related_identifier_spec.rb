require 'rails_helper'

module StashDatacite
  describe RelatedIdentifier do

    include Mocks::Datacite

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = create(:resource, user_id: user.id)
    end

    describe '#to_s' do
      it 'provides a reader-friendly description' do
        RelatedIdentifier::RelationTypesLimited.each_value do |rel_type|
          related_doi_value = "10.5555/#{Time.now.nsec}"
          rel_id = RelatedIdentifier.create(
            resource_id: @resource.id,
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
            resource_id: @resource.id,
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
            resource_id: @resource.id,
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
    describe '#work_type_friendly' do
      before(:each) do
        @related_identifier = create(:related_identifier, resource_id: @resource.id)
      end

      it 'handles undefined mapping' do
        expect(@related_identifier.work_type_friendly).to eq('Undefined')
      end

      it "handles a defined mapping like 'article'" do
        @related_identifier.update(work_type: 'article')
        expect(@related_identifier.work_type_friendly).to eq('Article')
      end
    end

    describe '#work_type_friendly_plural' do
      before(:each) do
        @related_identifier = create(:related_identifier, resource_id: @resource.id)
      end

      it 'handles undefined mapping' do
        expect(@related_identifier.work_type_friendly_plural).to eq('Undefineds')
      end

      it "handles a defined mapping like 'article'" do
        @related_identifier.update(work_type: 'article')
        expect(@related_identifier.work_type_friendly_plural).to eq('Articles')
      end

      # because the plural of software is software, not 'softwares' unless you're a 1337 h4ck3r or the Ruby language
      it "handles a defined mapping like 'software' without the wrong plural" do
        @related_identifier.update(work_type: 'software')
        expect(@related_identifier.work_type_friendly_plural).to eq('Software')
      end
    end

    # this also tests the self.valid_doi_format?(doi) since it really just wraps to make it available in the instance
    # from the class object so it's easily available in both places
    describe '#valid_doi_format?' do
      before(:each) do
        @related_identifier = create(:related_identifier, resource_id: @resource.id)
      end

      it 'returns false for not in standard url format' do
        @related_identifier.update(related_identifier: 'doi:10.1070/3788d')
        expect(@related_identifier.valid_doi_format?).to be false
      end

      it 'returns false for wildly wrong doi format' do
        @related_identifier.update(related_identifier: 'coming soon')
        expect(@related_identifier.valid_doi_format?).to be false
      end

      it 'returns true for correct and preferred doi format' do
        @related_identifier.update(related_identifier: 'https://doi.org/10.1070/3788d')
        expect(@related_identifier.valid_doi_format?).to be true
      end
    end

    describe 'self.standardize_doi(doi)' do
      it 'returns a correctly formatted doi for DOI: formatting' do
        expect(RelatedIdentifier.standardize_doi('doi:10.1070/3788d')).to eq('https://doi.org/10.1070/3788d')
      end

      it 'returns a correctly formatted doi for something that has a URL with what looks like a DOI in it' do
        expect(RelatedIdentifier.standardize_doi('https://example.org/freegan/10.1070/3788d')).to eq('https://doi.org/10.1070/3788d')
      end

      it 'returns the original string if nothing really looks like a DOI' do
        expect(RelatedIdentifier.standardize_doi('nog cat')).to eq('nog cat')
      end

      it 'returns the same string if the doi is already formatted nicely' do
        expect(RelatedIdentifier.standardize_doi('https://doi.org/10.1070/3788d')).to eq('https://doi.org/10.1070/3788d')
      end
    end

    describe '#live_url_valid?' do
      before(:each) do
        @related_identifier = create(:related_identifier, resource_id: @resource.id, related_identifier_type: 'doi')
      end

      it 'returns true for good url resolution' do
        doi = RelatedIdentifier.standardize_doi(Faker::Pid.doi)
        @related_identifier.update(related_identifier: doi)
        mock_good_doi_resolution(doi: doi)
        expect(@related_identifier.live_url_valid?).to be true
      end

      it 'returns false for 404 to url resolution' do
        doi = RelatedIdentifier.standardize_doi(Faker::Pid.doi)
        @related_identifier.update(related_identifier: doi)
        mock_bad_doi_resolution(doi: doi)
        expect(@related_identifier.live_url_valid?).to be false
      end

      it 'returns false for server error response to url resolution' do
        doi = RelatedIdentifier.standardize_doi(Faker::Pid.doi)
        @related_identifier.update(related_identifier: doi)
        mock_bad_doi_resolution_server_error(doi: doi)
        expect(@related_identifier.live_url_valid?).to be false
      end
    end

    describe '#valid_url_format?' do
      before(:each) do
        @related_identifier = create(:related_identifier, resource_id: @resource.id, related_identifier_type: 'doi')
      end

      it 'calls self.valid_url? from valid_url_format' do
        expect(RelatedIdentifier).to receive(:'valid_url?')
        @related_identifier.valid_url_format?
      end
    end

    describe 'self.standardize_format(string)' do

      it 'transforms a bunch of examples in an appropriate way (when it is able)' do
        expect(RelatedIdentifier.standardize_format(nil)).to eq('')
        expect(RelatedIdentifier.standardize_format('badid')).to eq('badid')
        expect(RelatedIdentifier.standardize_format('10.1010/12bogus.doi')).to eq('https://doi.org/10.1010/12bogus.doi')
        expect(RelatedIdentifier.standardize_format('GeNBaNk:PDQ128.338')).to eq('https://www.ncbi.nlm.nih.gov/nuccore/PDQ128.338')
        expect(RelatedIdentifier.standardize_format('Treebase:33837')).to eq('https://www.treebase.org/treebase-web/search/study/summary.html?id=33837')
        expect(RelatedIdentifier.standardize_format('http://monkeycalls.org/fun/10.1020/12345.fun.monkey.doi')).to eq('https://doi.org/10.1020/12345.fun.monkey.doi')
        expect(RelatedIdentifier.standardize_format('http://example.org/just/a/url')).to eq('http://example.org/just/a/url')
        expect(RelatedIdentifier.standardize_format('https://example.org/sordid.url')).to eq('https://example.org/sordid.url')
      end
    end

    describe 'self.identifier_type_from_str(string)' do
      it 'detects exact, preferred dois' do
        expect(RelatedIdentifier.identifier_type_from_str('https://doi.org/10.1030/3875nugget')).to eq('doi')
        expect(RelatedIdentifier.identifier_type_from_str('http://doi.org/10.1010/37566nnn')).to eq('doi')
        expect(RelatedIdentifier.identifier_type_from_str('https://dx.doi.org/1020/2874hh')).to eq('doi')
        expect(RelatedIdentifier.identifier_type_from_str('http://dx.doi.org/1020/2874hh')).to eq('doi')
      end

      it 'says everything else is a url' do
        expect(RelatedIdentifier.identifier_type_from_str(nil)).to eq('url')
        expect(RelatedIdentifier.identifier_type_from_str('10.1010/374foob')).to eq('url')
        expect(RelatedIdentifier.identifier_type_from_str(nil)).to eq('url')
        expect(RelatedIdentifier.identifier_type_from_str('I got a rock')).to eq('url')
        expect(RelatedIdentifier.identifier_type_from_str('http://snowball.de/3755')).to eq('url')
      end
    end

    describe 'self.valid_url?' do
      it 'returns false for bad URLs' do
        expect(RelatedIdentifier.valid_url?('grover')).to be(false)
        expect(RelatedIdentifier.valid_url?('tp://grover')).to be(false)
        expect(RelatedIdentifier.valid_url?('http://grover the cat')).to be(false)
        expect(RelatedIdentifier.valid_url?(nil)).to be(false)
        expect(RelatedIdentifier.valid_url?('')).to be(false)
      end

      it 'returns true for good urls' do
        expect(RelatedIdentifier.valid_url?('http://example.com/noogie?foo=bar&bag=cat#fun')).to be(true)
        expect(RelatedIdentifier.valid_url?('https://example.org/testing')).to be(true)
        expect(RelatedIdentifier.valid_url?('https://example.org:3000/my_port_is_good')).to be(true)
      end
    end
  end
end
