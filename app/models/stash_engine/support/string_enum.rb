require 'active_support/concern'

# Provides support for enums stored as Strings in the DB
# This can be dropped in Rails 5
module StashEngine

  module Support

    module StringEnum

      extend ActiveSupport::Concern

      class_methods do

        # rubocop:disable Style/OptionalBooleanParameter
        def string_enum(col, vals = [], default_val = nil, allow_nil = true)
          values = vals.map(&:to_s)

          values.each do |val|
            # Add a scope that returns all records for the given enum value
            scope val, -> { where(col: val) } unless respond_to?(val)
            # Add a getter and setter for the val
            define_getter_setter(col, val)
          end

          # Always initialize the model with the default (or first) enum value
          define_callbacks(col, default_val || vals.first)

          # Add a singleton method that returns the values
          define_singleton_method col.to_s.pluralize do
            values
          end

          # Add a nil validation if specified
          validates col, allow_nil: true if allow_nil
        end
        # rubocop:enable Style/OptionalBooleanParameter

        def define_getter_setter(col, val)
          # Add a boolean method for each value
          define_method "#{val}?" do
            read_attribute(col) == val
          end

          # Add a method that sets the status to the value
          define_method "#{val}!" do
            send("#{col}=", val)
          end
        end

        def define_callbacks(col, default_val)
          # Add a callback to set the col to the default
          after_initialize do
            send("#{col}=", default_val) unless try(col)
          end
        end

      end

    end

  end

end
