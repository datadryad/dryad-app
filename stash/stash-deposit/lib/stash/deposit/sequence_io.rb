require 'stringio'

module Stash
  module Deposit
    # A read-only `IO`-like that concatenates a sequence of strings or IOs.
    class SequenceIO

      # Creates a new {SequenceIO} concatenating the specified input sources.
      # Strings are wrapped internally as `StringIO`.
      #
      # @param inputs [Enumerable<String, IO>] an array of strings and/or IOs to
      #   concatenate
      def initialize(inputs)
        inputs  = [inputs] unless inputs.respond_to?(:[]) && inputs.respond_to?(:map)
        @inputs = to_ios(inputs)
        binmode if any_binmode(@inputs)
        @index = 0
        @input = @inputs[index] unless inputs.empty?
      end

      def size
        @size ||= inputs.inject(0) do |sum, input|
          raise "input #{input} does not respond to :size" unless input.respond_to?(:size)

          sum + input.size
        end
      end

      def read(length = nil, outbuf = nil)
        # use <= instead of == to get around https://github.com/bbatsov/rubocop/issues/3131
        return nil if size <= 0

        outbuf = outbuf ? outbuf.clear : ''
        length ? read_segment(length, outbuf) : read_fully(outbuf)
        outbuf
      end

      def binmode
        return self if binmode?

        inputs.each do |input|
          input.binmode if input.respond_to?(:binmode)
        end
        @binmode = true
        self
      end

      def binmode?
        @binmode
      end

      def close
        next_input! until input.nil?
      end

      def closed?
        input.nil? && index >= inputs.length
      end

      private

      attr_reader :input, :index, :inputs

      def read_fully(buffer)
        until input.nil?
          buffer << input.read(nil)
          next_input!
        end
      end

      def read_segment(length, buffer)
        return unless input && length > 0

        remaining = length
        if (result = input.read(length))
          buffer << result
          remaining = length - result.length
        end
        return unless remaining > 0

        next_input!
        read_segment(remaining, buffer)
      end

      # TODO: Array.pop! or something
      def next_input!
        input.close if input && input.respond_to?(:close)
        @index += 1
        @input = index < inputs.length ? inputs[index] : nil
      end

      def to_ios(inputs)
        inputs.map do |input|
          input.respond_to?(:read) ? input : StringIO.new(input.to_s)
        end
      end

      def any_binmode(ios)
        ios.each do |io|
          return true if io.respond_to?(:binmode?) && io.binmode?
        end
        false
      end
    end
  end
end
