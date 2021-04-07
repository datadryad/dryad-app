require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

# use example
# require 'stash/google/gmail'
#
# Stash::Google::GMail.list_messages(label: label)

module Stash
  module Google
    class GMail


      OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
      APPLICATION_NAME = "Dryad Ruby-Gmail library".freeze
      
      # The TOKEN_PATH file stores the user's access and refresh tokens, and is
      # created automatically when the authorization completes for the first
      # time. It is stored outside the main code directory, so we 
      TOKEN_PATH = "../token.yaml".freeze
      SCOPE = ::Google::Apis::GmailV1::AUTH_GMAIL_MODIFY
      
      # Ensure valid credentials, either by restoring from the saved token
      # or intitiating an OAuth2 authorization. If authorization is required,
      # the user's default browser will be launched to approve the request.
      #
      # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
      def self.authorize
        client_id = ::Google::Auth::ClientId.new(APP_CONFIG[:google][:gmail_client_id],
                                                 APP_CONFIG[:google][:gmail_client_secret])
        token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
        authorizer = ::Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
        user_id = "default"
        credentials = authorizer.get_credentials user_id
        
        if credentials.nil?
          url = authorizer.get_authorization_url base_url: OOB_URI
          puts "\nOpen the following URL in the browser and enter the " \
               "resulting code after authorization:\n\n#{url}\n"
          code = $stdin.gets
          credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: OOB_URI
          )
        end
        credentials
      end
      
      def self.initialize_gmail_token
        # Initialize the API
        @gmail = ::Google::Apis::GmailV1::GmailService.new
        @gmail.client_options.application_name = APPLICATION_NAME
        @gmail.authorization = authorize

        # Verify that we can read the user's labels, and the target label exists
        user_id = "me"
        label_results = @gmail.list_user_labels user_id
        if label_results.labels.empty?
          puts "Error: No labels found"
        else
          target = APP_CONFIG[:google][:gmail_processing_label]
          message = "Unable to locate label #{target}!"
          label_results.labels.each do |label|
            if label.name == target
              message = "Found label #{target}, initialization complete."
            end
          end
          puts "\n#{message}"
        end
      end


##### ######################################################
      
      def self.list_messages(label:)
        return unless label

        # TODO ######
      end

      class << self
        private

        def s3_credentials
          @s3_credentials ||= ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
        end


        def s3_bucket
          @s3_bucket ||= s3_resource.bucket(APP_CONFIG[:s3][:bucket])
        end

      end
    end
  end
end
