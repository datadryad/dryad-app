RSpec.shared_examples('user with no access') do
  it 'user has no access' do
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(choose_dashboard_path)
  end
end
