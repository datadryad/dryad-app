require 'httpclient'

class DryadNotifier

  def initialize(doi:, merritt_id:, version:)
    @doi = doi
    @merritt_id = merritt_id
    @version = version
  end

  def notify
    client = HTTPClient.new
    url = "#{Config.update_base_url}/doi:#{@doi}"

    # this callback allows following redirects from http to https, otherwise it will not go from one to other
    client.redirect_uri_callback = ->(_uri, res) {
      res.header['location'][0]
    }

    begin
      body = { 'record_identifier' => @merritt_id, 'stash_version' => @version }
      resp = client.patch(url, body, follow_redirect: true)
    rescue Errno::ECONNREFUSED, HTTPClient::ReceiveTimeoutError => ex
      Config.logger.error(ex.to_s)
      Config.logger.error("Couldn't PATCH update to #{url}")
      return false
    end
    if resp.status_code != 204
      Config.logger.error("PATCH to #{url} (merritt_id: #{@merritt_id}) returned a status code of #{resp.status_code}")
      return false
    end
    true
  end
end