module GenericFilesHelper

  include Mocks::Tenant
  include Mocks::Salesforce

  def generic_before
    mock_tenant!
    mock_salesforce!
    @user = create(:user, role: 'superuser')
    @resource = create(:resource, user_id: @user.id)
    @resource.current_resource_state.update(resource_state: 'submitted')
    @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
    @resource.reload
  end

  def generic_presign_expects(url, json_hash)
    # don't ask me how the encryption internals work, but we should receive the same response to the same request,
    # so this will detect if the signing function changes.
    response_code = get url, params: json_hash, as: :json
    expect(response_code).to eql(200)
    expect(response.body).to eql('a6c982052753f2377819a2d6162b60ca4b7b940794e882acc0b226f8ff803e99')
  end

  def generic_rejects_presign_expects(url, json_hash)
    @user.update(role: 'user')
    @user2 = create(:user, role: 'user')
    @resource.update(user_id: @user2.id) # not the owner
    response_code = get url, params: json_hash, as: :json
    expect(response_code).to eql(403)
  end

  def generic_new_db_entry_expects(json_hash, new_file)
    expect(new_file.upload_file_name).to eql(json_hash[:name])
    expect(new_file.upload_file_size).to eql(json_hash[:size])
    expect(new_file.upload_content_type).to eql(json_hash[:type])
    expect(new_file.original_filename).to eql(json_hash[:original])
  end

  def generic_returns_json_after_complete(url, json_hash)
    response_code = post url, params: json_hash
    expect(response_code).to eql(200)
    body = JSON.parse(response.body)
    new_file = StashEngine::GenericFile.first
    expect(body['new_file'].to_json).to eql(new_file.to_json)
  end

  def generic_validate_urls_expects(url)
    params = { 'url' => 'http://example.org/funbar.txt' }
    response_code = post url, params: params
    expect(response_code).to eql(200)

    body = JSON.parse(response.body)
    valid_url = body['valid_urls'].first
    expect(valid_url['upload_file_name']).to eql('funbar.txt')
    expect(valid_url['upload_file_size']).to eql(37_221)
    expect(valid_url['file_state']).to eql('created')
    expect(valid_url['url']).to eql('http://example.org/funbar.txt')
  end

  def generic_bad_urls_expects(url)
    params = { 'url' => 'http://example.org/foobar.txt' }
    response_code = post url, params: params
    expect(response_code).to eql(200)

    body = JSON.parse(response.body)
    invalid_url = body['invalid_urls'].first
    expect(invalid_url['url']).to eql(params['url'])
  end

  def generic_destroy_expects(url)
    response_code = patch url, as: :html
    expect(response_code).to eql(200)
    expect(body).to eql('OK')
  end
end
