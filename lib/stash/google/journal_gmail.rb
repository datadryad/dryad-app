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

      APPLICATION_NAME = 'Dryad JournalGmail library'.freeze
      SCOPE = ::Google::Apis::GmailV1::AUTH_GMAIL_MODIFY

      # Verify we can connect to GMail, we can read the user's labels, and the target label exists
      def self.validate_gmail_connection
        if user_labels.empty?
          puts 'Error: Unable to read user labels'
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
      rescue Signet::AuthorizationError => e
        puts "Error: Unable to authorize connection to GMail -- #{e}"
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
        # or intitiating a (web-based) OAuth2 authorization.
        def initialize_gmail_service
          credentials = ::Google::Auth::UserRefreshCredentials.make_creds(json_key_io: File.new(APP_CONFIG[:google][:token_path], 'r'),
                                                                          scope: SCOPE)

          if credentials.nil?
            puts "\nThis application is not yet authorized to read from GMail. To complete authorization:"
            puts '- Open the URL displayed below in a web browser'
            puts "- Choose the account #{APP_CONFIG[:google][:journal_account_name]}"
            puts '- Accept access for this service'
            puts "\n#{Rails.application.routes.url_helpers.gmail_auth_url}\n\n"
            return
          end

          if credentials.refresh_token.blank?
            puts 'Error: Credentials do not contain a refresh_token. Please reset this account and re-authenticate.'
            return
          end

          # The saved token file does not have the secret, so insert it
          credentials.client_secret = APP_CONFIG[:google][:gmail_client_secret]

          @gmail = ::Google::Apis::GmailV1::GmailService.new
          @gmail.client_options.application_name = APPLICATION_NAME
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
