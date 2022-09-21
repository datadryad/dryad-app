require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Example of use:
#
# require 'stash/google/journal_gmail'
# m = Stash::Google::JournalGMail.messages_to_process
# Stash::Google::JournalGMail.message_content(message: m.first)
#
# This class is focused on the processing needed for metadata emails from
# journals, but it could be expanded for more generic GMail functionality.
module Stash
  module Google
    class JournalGMail

      OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
      APPLICATION_NAME = 'Dryad JournalGmail library'.freeze

      # The TOKEN_PATH file stores the user's access and refresh tokens, and is
      # created automatically when the authorization completes for the first
      # time. It is stored outside the main code directory, so we
      TOKEN_PATH = '../token.yaml'.freeze
      SCOPE = ::Google::Apis::GmailV1::AUTH_GMAIL_MODIFY

      # Verify we can connect to GMail, we can read the user's labels, and the target label exists
      def self.validate_gmail_connection
        if user_labels.empty?
          puts 'Error: Unable to read user labels found'
        else
          message = "Error: Authorization to #{APP_CONFIG[:google][:journal_account_name]} is working, " \
                    "but unable to locate the target label `#{processing_label_name}`"
          user_labels.each do |label|
            if label.name == processing_label_name
              message = "Initialization complete: Found label `#{processing_label_name}` in account #{APP_CONFIG[:google][:journal_account_name]}"
            end
          end
          puts "\n#{message}"
        end
      end

      def self.user_labels
        gmail.list_user_labels('me').labels
      end

      # The messages returned by this method are stubs, containing only the message id. For actual
      # information about each message, you must use one of the methods that start with "message_"
      def self.messages_to_process
        return unless processing_label.present?

        gmail.list_user_messages('me', label_ids: processing_label.id).messages
      end

      def self.message_content(message:)
        return unless message.present?

        payload = gmail.get_user_message('me', message.id)&.payload
        find_content(payload)
      end

      def self.message_header(message:, header_name:)
        return unless message.present? && header_name.present?

        headers = gmail.get_user_message('me', message.id)&.payload&.headers
        return unless headers.present?

        header_val = nil
        headers.each do |header|
          header_val = header.value if header.name == header_name
        end
        header_val
      end

      def self.message_subject(message:)
        message_header(message: message, header_name: 'Subject')
      end

      def self.message_sender(message:)
        message_header(message: message, header_name: 'X-Original-From') ||
          message_header(message: message, header_name: 'X-Original-Sender')
      end

      def self.message_labels(message:)
        return unless message.present?

        gmail.get_user_message('me', message.id)&.label_ids
      end

      def self.remove_processing_label(message:)
        return unless processing_label

        mod_request = ::Google::Apis::GmailV1::ModifyMessageRequest.new
        mod_request.remove_label_ids = [processing_label.id]
        gmail.modify_message('me', message.id, mod_request)
      end

      def self.add_error_label(message:)
        return unless error_label

        mod_request = ::Google::Apis::GmailV1::ModifyMessageRequest.new
        mod_request.add_label_ids = [error_label.id]
        gmail.modify_message('me', message.id, mod_request)
      end

      def self.process
        messages = Stash::Google::JournalGMail.messages_to_process
        return unless messages

        messages.each do |m|
          puts "Processing message #{m.id} -- #{Stash::Google::JournalGMail.message_subject(message: m)}"
          content = Stash::Google::JournalGMail.message_content(message: m)
          result = StashEngine::Manuscript.from_message_content(content: content)
          remove_processing_label(message: m)
          if result.success?
            puts " -- created Manuscript #{result.payload.id}"
          else
            puts " -- ERROR #{result.error} -- Adding error label to #{m.id}"
            add_error_label(message: m)
          end
        end
      end

      def self.gmail
        @gmail ||= initialize_gmail_service
      end

      #######################################################
      class << self
        private

        # Locate the textual content of a message's payload.
        # Simple emails contain the content directly in a "body" object. But MIME Multipart messages
        # can have a tree of "parts". Traverse the tree until we find a part that has textual content.
        def find_content(payload)
          return nil unless payload.present?

          content = payload.body&.data
          return content if content.present?

          parts = payload.parts
          parts.each do |part|
            content = find_content(part)
            return content if content.present?
          end
        end

        # Ensure valid credentials, either by restoring from a saved token
        # or intitiating a (command-line) OAuth2 authorization.
        def initialize_gmail_service
          @gmail = ::Google::Apis::GmailV1::GmailService.new
          @gmail.client_options.application_name = APPLICATION_NAME

          client_id = ::Google::Auth::ClientId.new(APP_CONFIG[:google][:gmail_client_id],
                                                   APP_CONFIG[:google][:gmail_client_secret])
          token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
          #authorizer = ::Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
          authorizer = ::Google::Auth::WebUserAuthorizer.new(client_id, SCOPE, token_store)
          user_id = session[:user_id]
          puts "user_id: #{user_id}"
          
          credentials = authorizer.get_credentials('default')

          if credentials.nil?
            
            url = authorizer.get_authorization_url(base_url: OOB_URI)
            puts "\nThis application is not yet authorized to read from GMail. To complete authorization:"
            puts '- Open the URL displayed below in a web browser'
            puts "- Choose the account #{APP_CONFIG[:google][:journal_account_name]}"
            puts '- Accept access for this service'
            puts '- Copy the resulting auth code and paste it below'
            puts "\n#{url}\n\n"
            print 'AUTH CODE: '
            code = $stdin.gets
            # [Google::Auth::UserRefreshCredentials] OAuth2 credentials
            credentials = authorizer.get_and_store_credentials_from_code(user_id: 'default',
                                                                         code: code,
                                                                         base_url: OOB_URI)
          end
          @gmail.authorization = credentials
          @gmail
        end

        def processing_label_name
          APP_CONFIG[:google][:journal_processing_label]
        end

        def label_by_name(name: nil)
          return unless name.present? && user_labels.present?

          found_label = nil
          user_labels.each do |label|
            found_label = label if label.name == name
          end
          found_label
        end

        def processing_label
          @processing_label ||= label_by_name(name: processing_label_name)
        end

        def error_label
          @error_label ||= label_by_name(name: APP_CONFIG[:google][:journal_error_label])
        end

      end
    end
  end
end
