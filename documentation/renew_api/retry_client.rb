require 'rest-client'
require 'json'
require 'byebug'

class RetryClient

  attr_reader :app_id, :secret, :scheme_host_port, :token

  def initialize(app_id:, secret:, scheme_host_port:)
    @app_id = app_id
    @secret = secret
    @scheme_host_port = scheme_host_port
  end

  # this will work for basic requests like get, post, put, patch and follows the rest-client arguement format after the
  # method
  def retry(method, *args)
    retries ||= 0
    raise 'wrong number of arguments, should be 2 or 3 and follow RestClient basic examples.' unless [2, 3].include?(args.length)
    if args.length == 2
      RestClient.send(method, url_for(args[0]), combine(args[1]))
    else
      RestClient.send(method, url_for(args[0]), args[1], combine(args[2]))
    end

  rescue RestClient::Unauthorized => ex
    raise ex unless get_token # refreshes token if successful
    retry if (retries += 1) < 2
    raise ex
  end

  def get_token
    response = RestClient.post "#{scheme_host_port}/oauth/token", {
        grant_type: 'client_credentials',
        client_id: app_id,
        client_secret: secret
    }
    @token = JSON.parse(response)['access_token']
  end

  def combine(hash)
    headers = { 'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'Authorization' => "Bearer #{token}" }
    headers.merge(hash)
  end

  def url_for(path)
    "#{scheme_host_port}#{path}"
  end

end