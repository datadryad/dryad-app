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
      
      # The file token.yaml stores the user's access and refresh tokens, and is
      # created automatically when the authorization flow completes for the first
      # time.
      TOKEN_PATH = "token.yaml".freeze
      SCOPE = ::Google::Apis::GmailV1::AUTH_GMAIL_MODIFY
      
      # Ensure valid credentials, either by restoring from the saved credentials
      # files or intitiating an OAuth2 authorization. If authorization is required,
      # the user's default browser will be launched to approve the request.
      #
      # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
      def self.authorize
        client_id = ::Google::Auth::ClientId.new(APP_CONFIG[:google][:gmail_client_id],
                                                 APP_CONFIG[:google][:gmail_client_secret])
        puts "auth b #{client_id}"
        token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
        puts "auth c #{token_store}"
        authorizer = ::Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
        user_id = "default"
        credentials = authorizer.get_credentials user_id
        puts "auth d #{credentials}"
        
        if credentials.nil?
          url = authorizer.get_authorization_url base_url: OOB_URI
          puts "Open the following URL in the browser and enter the " \
               "resulting code after authorization:\n" + url
          code = gets
          credentials = authorizer.get_and_store_credentials_from_code(
            user_id: user_id, code: code, base_url: OOB_URI
          )
        end
        credentials
      end
      
      def self.init
        # Initialize the API
        puts "Init a"
        service = ::Google::Apis::GmailV1::GmailService.new
        puts "Init b"
        service.client_options.application_name = APPLICATION_NAME
        puts "Init c"
        service.authorization = authorize
        puts "Init d"

        # Show the user's labels
        user_id = "me"
        result = service.list_user_labels user_id
        puts "Labels:"
        puts "No labels found" if result.labels.empty?
        result.labels.each { |label| puts "- #{label.name}" }
        nil
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
