module StashEngine
  class BaseSenderService

    attr_reader :data_file, :resource

    def initialize(data_file, resource = nil)
      credentials = ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
      @client     = Aws::Lambda::Client.new(region: APP_CONFIG[:s3][:region], credentials: credentials)
      @data_file  = data_file
      @resource   = resource
    end

    def trigger_call(function_name)
      return { triggered: false, msg: 'No API token' } if StashEngine::ApiToken.token.nil?

      response = @client.invoke(
        {
          function_name: function_name,
          invocation_type: 'Event',
          log_type: 'None',
          payload: payload
        }
      )

      if response.status_code == 202 # true with no msg
        render_success
      else
        render_error
      end
    end

    private

    def payload
      JSON.generate(
        {
          download_url: data_file.url || data_file.s3_staged_presigned_url,
          file_mime_type: data_file.upload_content_type,
          callback_url: callback_url,
          token: StashEngine::ApiToken.token
        }
      )
    end

    def render_success
      { triggered: true, msg: '' }
    end

    def render_error
      item = {
        triggered: false,
        msg: "#{fail_message}" \
             "\nstatus code: #{response.status_code}" \
             "\nfunction error: #{response.function_error}" \
             "\nlog_result: #{response.log_result}" \
             "\npayload: #{response.payload}" \
             "\nexecuted version: #{response.executed_version}"
      }

      logger.error(item)
      { triggered: false, msg: item }
    end

    def fail_message
      raise NotImplementedError, 'Subclass must implement #fail_message'
    end

    def callback_url
      raise NotImplementedError, 'Subclass must implement #callback_url'
    end
  end
end
