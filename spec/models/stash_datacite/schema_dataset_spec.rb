module StashDatacite
  module Resource
    describe SchemaDataset do

      before(:each) do
        @user = create(:user,
                       email: 'lmuckenhaupt@example.edu',
                       tenant_id: 'dataone')

        @resource = create(:resource, user: @user)
        @resource.download_uri = "https://repo.example.edu/#{@resource.identifier_str}.zip"
        @resource.save

        schema_dataset = SchemaDataset.new(resource: @resource)

        # Should be like spec/data/example.json
        json_hash = schema_dataset.generate
        @actual = JSON.parse(json_hash.to_json)
      end

      it 'generates schema.org JSON' do
        expect(@actual['@context']).to eq('http://schema.org')
      end

      it 'has identifiers in the correct fields' do
        expect(@actual['@id']).to eq("https://doi.org/#{@resource.identifier.identifier}")
        expect(@actual['identifier']).to eq("https://doi.org/#{@resource.identifier.identifier}")
      end

      it 'has the correct title' do
        expect(@actual['name']).to eq(@resource.title)
      end

      it 'has the correct license' do
        expect(@actual['license']['license']).to eq(@resource.rights.first.rights_uri)
      end

      it 'has the correct publisher information' do
        expect(@actual['publisher']['@id']).to eq('https://datadryad.org')
      end

      it 'has the correct ROR affiliation' do
        expect(@actual['creator']['affiliation']['sameAs']).to eq(@resource.authors.first.affiliation.ror_id)
      end

      it 'has the correct username and ORCID' do
        expect(@actual['creator']['name']).to eq(@resource.authors.first.author_standard_name)
        expect(@actual['creator']['sameAs']).to eq("http://orcid.org/#{@resource.authors.first.author_orcid}")
      end

      it 'has the correct download link' do
        expect(@actual['distribution']['contentUrl']).to include('api/v2/datasets/doi')
      end
    end
  end
end
