class DownloadService
  attr_reader :request, :user_id

  def initialize(request, user_id)
    @request = request
    @user_id = user_id
  end

  def create(file_id, resource_id, as_zip: false, from_api: false)
    Download.create(
      resource_id: resource_id,
      file_id: file_id,
      from_api: from_api,
      as_zip: as_zip,
      ip: request&.remote_ip,
      user_agent: request&.user_agent,
      user_id: user_id
    )
  end
end
