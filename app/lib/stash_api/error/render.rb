# frozen_string_literal: true

# Extracts information from error objects and returns a json friendly for StashApi responses
# kudos for the inspiration to https://github.com/stitchfix/stitches/blob/master/lib/stitches/errors.rb
#
module StashApi
  module Error
    class Render
      include Enumerable

      def self.from(object_or_exception)
        if object_or_exception.class < ActiveRecord::Base ||
           object_or_exception.class < ActiveModel::Validations
          from_active_record object_or_exception
        else
          # TODO: use something like bugsnag to send a notification
          #   if the exception has an original exception attached
          #   or if the exception is not a SafeError
          from_exception object_or_exception
        end
      end

      def initialize(errors)
        @errors = errors
      end

      # not really needed, but useful
      def size
        @errors.size
      end

      # need to implement #each for json encoding purposes
      def each
        if block_given?
          @errors.each do |error|
            yield error
          end
        else
          @errors.each
        end
      end

      def self.from_active_record(object)
        errors = object.errors.to_hash.map do |field, _errors|
          message = if field != :base && object.respond_to?(field) && object.send(field).respond_to?(:errors)
                      object.send(field).errors.full_messages.sort.join(', ')
                    else
                      object.errors.full_messages_for(field).sort.join(', ')
                    end

          StashApi::Error::Decorator.new(code: 'validation_error', message: message, field: field.to_s)
        end

        new(errors)
      end

      def self.from_exception(exception)
        # TODO: consider setting the error code to `generic` for StandardError exceptions
        code = exception.class.name.demodulize.gsub(/Error$/, '').underscore
        metadata = exception.respond_to?(:metadata) ? exception.metadata : {}

        new([
              StashApi::Error::Decorator.new(
                code: code,
                message: exception.message,
                metadata: metadata.as_json
              )
            ])
      end
    end
  end
end
