require 'stringio'

module Stash
  module Sword2
    class SequenceIO

      def initialize(inputs)
        inputs = [inputs] unless inputs.respond_to?(:[]) && inputs.respond_to?(:map)
        @inputs = inputs.map do |input|
          input.binmode if input.respond_to?(:binmode)
          input.respond_to?(:read) ? input : StringIO.new(input.to_s)
        end
        self.index = 0
        self.input = @inputs[index] unless inputs.empty?
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

      def binmode?
        true
      end

      def close
        next_input! until input.nil?
      end

      def closed?
        input.nil? && index >= inputs.length
      end

      private

      attr_accessor :input
      attr_accessor :index
      attr_reader :inputs

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
        self.index += 1
        self.input = index < inputs.length ? inputs[index] : nil
      end

    end
  end
end
