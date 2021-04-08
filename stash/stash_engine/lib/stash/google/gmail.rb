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
      APPLICATION_NAME = "Dryad Rails-Gmail library".freeze
      
      # The TOKEN_PATH file stores the user's access and refresh tokens, and is
      # created automatically when the authorization completes for the first
      # time. It is stored outside the main code directory, so we 
      TOKEN_PATH = "../token.yaml".freeze
      SCOPE = ::Google::Apis::GmailV1::AUTH_GMAIL_MODIFY

      # Verify we can connect to GMail, we can read the user's labels, and the target label exists
      def self.validate_gmail_connection
        user_id = "me"
        label_results = gmail.list_user_labels user_id
        if label_results.labels.empty?
          puts "Error: Unable to read user labels found"
        else
          target = APP_CONFIG[:google][:gmail_processing_label]
          message = "Error: Authorization to #{APP_CONFIG[:google][:gmail_account_name]} is working, but unable to locate the target label `#{target}`"
          label_results.labels.each do |label|
            if label.name == target
              message = "Initialization complete: Found label `#{target}` in account #{APP_CONFIG[:google][:gmail_account_name]}"
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
        
        def gmail
          @gmail ||= initialize_gmail_service
        end

        # Ensure valid credentials, either by restoring from a saved token
        # or intitiating a (command-line) OAuth2 authorization. 
        #
        # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
        def initialize_gmail_service
          @gmail = ::Google::Apis::GmailV1::GmailService.new
          @gmail.client_options.application_name = APPLICATION_NAME
          
          client_id = ::Google::Auth::ClientId.new(APP_CONFIG[:google][:gmail_client_id],
                                                   APP_CONFIG[:google][:gmail_client_secret])
          token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
          authorizer = ::Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
          user_id = "default"
          credentials = authorizer.get_credentials(user_id)
          
          if credentials.nil?
            url = authorizer.get_authorization_url(base_url: OOB_URI)
            puts "\nThis application is not yet authorized to read from GMail. To complete authorization:"
            puts "- Open the URL displayed below in a web browser"
            puts "- Choose the account #{APP_CONFIG[:google][:gmail_account_name]}"
            puts "- Accept access for this service"
            puts "- Copy the resulting auth code and paste it below"
            puts "\n#{url}\n\n"
            print "AUTH CODE: "
            code = $stdin.gets
            credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id,
                                                                         code: code,
                                                                         base_url: OOB_URI)
          end
          @gmail.authorization = credentials
          @gmail
        end

      end
    end
  end
end
