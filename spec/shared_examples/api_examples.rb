# This expects @metadata_hash to be set in parent test
RSpec.shared_examples('API submission flow') do |can_submit, submit_response|
  it 'has proper flow' do
    metadata_hash = @metadata_hash

    ### Test token - returns welcome message and authenticated user id
    post '/api/v2/test', headers: headers
    json_response = response_body_hash
    expect(/Welcome application owner.+$/).to match(json_response[:message])
    expect(user.id).to eql(json_response[:user_id])

    ### LIST dataset - returns no datasets
    get '/api/v2/datasets', headers: headers
    json_response = response_body_hash
    expect(json_response[:total]).to eq(0)

    response_code = post '/api/v2/datasets', params: metadata_hash.to_json, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)

    doi = json_response[:identifier]
    identifier = StashEngine::Identifier.find_by(identifier: doi.split(':').last)
    resource_id = json_response[:id]
    in_author = metadata_hash[:authors].first
    out_author = json_response[:authors].first
    # Update user as primary author
    user.update(orcid: out_author[:orcid])

    expect(/doi:10./).to match(doi)
    expect(metadata_hash[:title]).to eq(json_response[:title])
    expect(metadata_hash[:abstract]).to eq(json_response[:abstract])
    expect(json_response[:id]).to eq(resource_id)
    expect(out_author[:email]).to eq(in_author[:email])
    expect(out_author[:affiliation]).to eq(in_author[:affiliation])
    expect(out_author[:affiliation]).to eq(journal.title)
    expect(json_response[:title]).to eq(title)
    expect(json_response[:keywords]).to eq(metadata_hash[:keywords])
    expect(json_response[:fieldOfScience]).to eq(metadata_hash[:fieldOfScience])
    expect(json_response[:versionNumber]).to eq(1)
    expect(json_response[:versionStatus]).to eq('in_progress')
    expect(json_response[:curationStatus]).to eq('In progress')
    expect(json_response[:lastModificationDate]).to eq(Date.today.to_s)
    expect(json_response[:visibility]).to eq('restricted')
    expect(json_response[:userId]).to eq(user.id)
    expect(json_response[:license]).to eq(Stash::Wrapper::License::CC_ZERO.uri.to_s)
    expect(json_response[:editLink]).to eq("/edit/#{CGI.escape(doi)}/#{identifier.edit_code}")

    ### SHOW dataset
    response_code = get "/api/v2/datasets/#{CGI.escape(doi)}", headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:identifier]).to eq(doi)
    expect(json_response[:id]).to eq(resource_id)

    ### UPDATE dataset
    update_params = metadata_hash.merge({ abstract: 'New abstract', methods: 'New Method' })
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}", params: update_params.to_json, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:identifier]).to eq(doi)
    expect(json_response[:id]).to eq(resource_id)
    expect(json_response[:abstract]).to eq(update_params[:abstract])
    expect(json_response[:methods]).to eq(update_params[:methods])

    ### UPLOAD file
    file = fixture_file_upload('spec/fixtures/zipfiles/test_zip.zip')
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}/files/test_zip.zip", params: { file: file }, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)
    expect(json_response[:url]).to be_nil
    expect(json_response[:path]).to eq('test_zip.zip')
    expect(json_response[:status]).to eq('created')

    ### UPLOAD README file
    file = fixture_file_upload('spec/fixtures/README.md')
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}/files/README.md", params: { file: file }, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)
    expect(json_response[:url]).to be_nil
    expect(json_response[:path]).to eq('README.md')
    expect(json_response[:status]).to eq('created')

    ### LIST dataset versions
    response_code = get "/api/v2/datasets/#{CGI.escape(doi)}/versions", headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:count]).to eq(1)
    expect(json_response[:total]).to eq(1)
    expect(json_response[:_embedded]['stash:versions'].first[:title]).to eq(title)
    expect(json_response[:_embedded]['stash:versions'].first[:versionNumber]).to eq(1)
    version_files_path = json_response[:_embedded]['stash:versions'].first['_links']['stash:files'][:href]

    ### LIST dataset version files
    response_code = get version_files_path, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:count]).to eq(2)
    expect(json_response[:total]).to eq(2)
    expect(json_response[:_embedded]['stash:files'].map { |f| f[:path] }).to match_array(['README.md', 'test_zip.zip'])
    expect(json_response[:_embedded]['stash:files'].map { |f| f[:status] }).to match_array(%w[created created])

    ### SUBMIT dataset
    params = { op: 'replace', path: '/versionStatus', value: 'submitted' }
    response_code = patch "/api/v2/datasets/#{CGI.escape(doi)}", params: params.to_json, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(submit_response[:status])

    if can_submit
      expect(json_response[:identifier]).to eq(doi)
      expect(json_response[:id]).to eq(resource_id)
      expect(json_response[:versionStatus]).to eq('processing')
      expect(json_response[:curationStatus]).to eq('Processing')
    else
      expect(json_response[:error]).to eq(submit_response[:error])
    end
  end
end
