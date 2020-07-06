require 'httpclient'

class DryadNotifier

  def initialize(doi:, merritt_id:, version:)
    @doi = doi
    @merritt_id = merritt_id
    @version = version
  end

  # rubocop:disable Metrics/MethodLength
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
    rescue Errno::ECONNREFUSED, HTTPClient::ReceiveTimeoutError => e
      Config.logger.error(e.to_s)
      Config.logger.error("Couldn't PATCH update to #{url}")
      return false
    end
    if resp.status_code != 204
      if Rails.env == 'production'
        Config.logger.error("PATCH to #{url} (merritt_id: #{@merritt_id}) returned a status code of #{resp.status_code}")
        return false
      else
        Config.logger.warn("PATCH to #{url} (merritt_id: #{@merritt_id}) returned a status code of #{resp.status_code}")
      end
    end
    true
  end
  # rubocop:enable Metrics/MethodLength

end
