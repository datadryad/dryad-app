require 'stringio'

module Stash
  module Sword2
    class ArrayStream

      attr_reader :inputs

      # TODO: make these private
      attr_accessor :stream_index
      attr_accessor :input

      def initialize(inputs)
        inputs = [inputs] unless inputs.respond_to?(:map)
        @inputs = inputs.map do |input|
          if input.respond_to?(:read)
            input
          else
            StringIO.new(input.to_s)
          end
        end
        self.stream_index = 0
        @input = @inputs[0] unless @inputs.empty?
      end

      def size
        @size ||= inputs.inject(0) do |sum, input|
          raise "#{input} does not respond to :size" unless input.respond_to?(:size)
          sum + input.size
        end
      end

      def read(length = nil, outbuf = nil)
        if outbuf
          outbuf.clear
        else
          outbuf = ''
        end
        return '' if length == 0
        return nil unless read_chars(length, outbuf)
        outbuf
      end

      def close
        input.close if input
        self.stream_index = inputs.size
      end

      private

      def read_chars(length, outbuf)
        return nil unless input
        str = input.read(length)
        if str && str.length > 0
          outbuf << str
          str.length
        else
          next_stream
          read_chars(length, outbuf)
        end
      end

      def has_more_streams
        stream_index < inputs.size
      end

      def next_stream
        self.input.close if self.input
        if has_more_streams
          self.stream_index += 1
          self.input = inputs[self.stream_index]
        else
          self.input = nil
        end
      end

    end
  end
end
