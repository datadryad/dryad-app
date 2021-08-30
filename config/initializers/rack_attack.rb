###############################################
# Rack-Attack configuration for rate limiting
###############################################

# Exemptions
# ------------------

# IPs to allow outright
# Rack::Attack.safelist_ip("98.27.57.189")

# Blocks
# -------------------

# IPs to block outright
# Rack::Attack.blocklist_ip("5.6.7.8")

# Set a long block period for any client that is explicitly looking for security holes
Rack::Attack.blocklist("fail2ban") do |req|
  Rack::Attack::Fail2Ban.filter("fail2ban-pentest-#{req.ip}", maxretry: 1, findtime: 1.day, bantime: 1.day) do
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
      req.path.include?("/etc/passwd") ||
      req.path.include?("wp-admin") ||
      req.path.include?("wp-login") ||
      /\S+\.php/.match?(req.path)
  end
end

# Throttling
# -------------------

# The number of requests allowed within each time limit
limit_proc = proc { |req|
  puts "XXXXX req.path #{req.path}"
  if req.path.include?('/stash/downloads/download_resource')
    # Throttle zip downloads to a slower rate than other requests,
    # since it is expensive for Merritt to asemble the zip files
    10
  else    
    120
  end
}

# Baseline throttle of all requests by IP
# allow no more than `limit` requests per `period`
# Returns the IP address, which will be tracked with a count of how many requests are made by each IP
# but ignore requests for assets, which are just part of each page
Rack::Attack.throttle('requests by IP', limit: limit_proc, period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets')
end


# When a client is throttled, return useful information to them
Rack::Attack.throttled_response = lambda do |env|
  match_data = env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
  }

  [ 429, headers, ["This request has been denied due to exceeding the rate limit.\n"]]
end

#  
