###############################################
# Rack-Attack configuration for rate limiting
###############################################

# Exemptions
# ------------------

# IPs to allow outright
Rack::Attack.safelist_ip('127.0.0.1')
Rack::Attack.safelist_ip('::1')

# Blocks
# -------------------

# IPs to block outright
# Rack::Attack.blocklist_ip("5.6.7.8")

# Set a long block period for any client that is explicitly looking for security holes
Rack::Attack.blocklist('malicious_clients') do |req|
  Rack::Attack::Fail2Ban.filter("fail2ban_malicious_#{req.ip}", maxretry: 1, findtime: 1.day, bantime: 1.day) do
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?('/etc/passwd') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      /\S+\.php/.match?(req.path)
  end
end



# Block repeated malicious content type checks
# After 2 requests, block all requests from that IP for 1 day.
Rack::Attack.blocklist('malicious_content_type') do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 2, findtime: 1.day, bantime: 1.day) do
    (req.env["HTTP_ACCEPT"].present? && req.env["HTTP_ACCEPT"].include?('$')) || 
    (req.content_type.present? && req.content_type.include?('$'))
  end
end


# Throttling
# -------------------

# Throttling allows no more than `limit` requests per `period`
# Each throttle takes a block that returns a "discriminator" for the user and type of call.
# Rack-attack counts the requests for each discriminator within the period and manages the
# throttle notifications.
#
# Each throttle is independent, so it is possible for a single request to be counted in multiple
# discriminators.

# Baseline throttle all requests by IP
# But don't return anything for /assets, which are just part of each page and should not be tracked.
# Also, don't throttle AWS presign requests for upload chunks that will be sent to S3 for files
Rack::Attack.throttle('all_requests_by_IP', limit: APP_CONFIG[:rate_limit][:all_requests], period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets') || req.path.match(%r{^/stash/[a-z]+_file/presign_upload/\d+})
end

# Zip downloads have a much lower limit than other requests,
# since it is expensive for Merritt to asemble the zip files.
Rack::Attack.throttle('zip_downloads', limit: APP_CONFIG[:rate_limit][:zip_downloads], period: 1.minute) do |req|
  "zip_download_#{req.ip}" if req.path.start_with?('/stash/downloads/download_resource') ||
                              req.path.match(/api.*(version|dataset).*download/)
end

# Registered API users get preferential treatment over anonymous users. Assume API users have
# a valid auth code. If the auth data is bad, it will be caught and blocked by the API controllers.
Rack::Attack.throttle('API_requests_by_registered_users', limit: APP_CONFIG[:rate_limit][:api_requests_auth], period: 1.minute) do |req|
  "api-user-#{req.ip}" if req.path.start_with?('/api') && req.has_header?('HTTP_AUTHORIZATION')
end

Rack::Attack.throttle('API_requests_by_anonymous_users', limit: APP_CONFIG[:rate_limit][:api_requests_anon], period: 1.minute) do |req|
  "anon-api-user-#{req.ip}" if req.path.start_with?('/api') && !req.has_header?('HTTP_AUTHORIZATION')
end

Rack::Attack.throttle('v1_resource_requests', limit: APP_CONFIG[:rate_limit][:api_requests_v1], period: 1.minute) do |req|
  "v1-api-user-#{req.ip}" if req.path.start_with?('/resource')
end

# When a client is throttled, return useful information in the response
Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [429, headers, ["Request rejected due to rate limits.\n"]]
end

# Log the blocked requests
ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, _start, _finish, _request_id, payload|
  req = payload[:request]
  Rails.logger.info "[Rack::Attack][Blocked] name: #{name}, rule: #{req.env['rack.attack.matched']} remote_ip: #{req.ip}, " \
                    "path: #{req.path}, agent: #{req.user_agent}"
end
