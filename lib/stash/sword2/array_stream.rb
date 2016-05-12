require 'stringio'

module Stash
  module Sword2
    class ArrayStream

      def initialize(inputs)
        inputs = [inputs] unless inputs.respond_to?(:[]) && inputs.respond_to?(:map)
        @inputs = inputs.map do |input|
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
        return nil if size == 0
        outbuf = outbuf ? outbuf.clear : ''
        length ? read_segment(length, outbuf) : read_fully(outbuf)
        outbuf
      end

      def close
        while input != nil
          next_input!
        end
      end

      private

      attr_accessor :input
      attr_accessor :index
      attr_reader :inputs

      def read_fully(buffer)
        while input != nil
          buffer << input.read(nil)
          next_input!
        end
      end

      def read_segment(length, buffer)
        return unless input && length > 0
        result = input.read(length)
        if result
          buffer << result
          remaining = length - result.length
          if remaining > 0
            next_input!
            read_segment(remaining, buffer)
          end
        else
          next_input!
          read_segment(length, buffer)
        end
      end

      # TODO: Array.pop! or something
      def next_input!
        input.close if input && input.respond_to?(:close)
        if index + 1 < inputs.length
          self.index += 1
          self.input = inputs[index]
        else
          self.index = inputs.size
          self.input = nil
        end
      end

    end
  end
end
