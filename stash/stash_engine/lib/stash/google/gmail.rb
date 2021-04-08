require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

# use example
# require 'stash/google/gmail'
#
# Stash::Google::GMail.list_messages(label: label)
#
# This class is currently focused on only the processing needed for processing metadata emails from
# journals, but it can easily be expanded for more generic GMail functionality.

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
        labels = gmail.list_user_labels("me").labels
        if labels.empty?
          puts "Error: Unable to read user labels found"
        else
          message = "Error: Authorization to #{APP_CONFIG[:google][:gmail_account_name]} is working, but unable to locate the target label `#{processing_label_name}`"
          labels.each do |label|
            if label.name == processing_label_name
              message = "Initialization complete: Found label `#{processing_label_name}` in account #{APP_CONFIG[:google][:gmail_account_name]}"
            end
          end
          puts "\n#{message}"
        end
      end
      
      def self.messages_to_process
        messages = gmail.list_user_messages("me", label_ids: processing_label.id).messages
        return unless messages.present?
        messages.each do |message|
          puts "M #{message.id} -- #{message}"
        end
      end
      
      #######################################################
      
      class << self
        private
        
        def gmail
          @gmail ||= initialize_gmail_service
        end

        # Ensure valid credentials, either by restoring from a saved token
        # or intitiating a (command-line) OAuth2 authorization. 
        def initialize_gmail_service
          @gmail = ::Google::Apis::GmailV1::GmailService.new
          @gmail.client_options.application_name = APPLICATION_NAME
          
          client_id = ::Google::Auth::ClientId.new(APP_CONFIG[:google][:gmail_client_id],
                                                   APP_CONFIG[:google][:gmail_client_secret])
          token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
          authorizer = ::Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
          credentials = authorizer.get_credentials("default")
          
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
            # [Google::Auth::UserRefreshCredentials] OAuth2 credentials
            credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id,
                                                                         code: code,
                                                                         base_url: OOB_URI)
          end
          @gmail.authorization = credentials
          @gmail
        end

        def processing_label_name
          APP_CONFIG[:google][:gmail_processing_label]
        end

        def processing_label
          return @processing_label unless @processing_label.blank?
          
          labels = gmail.list_user_labels("me").labels
          unless labels.empty?            
            labels.each do |label|
              if label.name == processing_label_name
                @processing_label = label
              end
            end
          end
          @processing_label
        end

      end
    end
  end
end
