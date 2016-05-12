require 'spec_helper'
require 'tempfile'

module Stash
  module Sword2
    describe ArrayStream do

      attr_reader :len
      attr_reader :content
      attr_reader :stream
      attr_reader :inputs
      attr_reader :outbuf

      before(:each) do
        @outbuf = 'elvis'
      end

      after(:each) do
        stream.close if stream
      end

      describe 'a string' do

        before(:each) do
          @len = 100
          charset = Array('A'..'Z') + Array('a'..'z')
          @content = Array.new(len) { charset.sample }.join
          @stream = ArrayStream.new(@content)
        end

        it 'reads' do
          expect(stream.read).to eq(content)
        end

        it 'reads into a buffer' do
          expect(stream.read(len, outbuf)).to eq(content)
          expect(outbuf).to eq(content)
        end

        it 'reads n < length chars' do
          length = len/2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end
        it 'reads n == length chars'
        it 'reads n > length chars'
      end

      describe 'a file' do

        attr_reader :tempfile

        before(:each) do
          @len = 100
          @content = Random.new.bytes(len)

          f = Tempfile.new(%w(array_stream-spec bin))
          f.binmode
          @tempfile = f.path
          begin
            f.write(content)
          ensure
            f.close
          end

          # Tempfile.new(%w(array_stream-spec bin)) do |f|
          #   f.binwrite(content)
          #   self.tempfile = f.path
          # end

          @inputs = File.open(@tempfile, 'rb')
          @stream = ArrayStream.new(@inputs)
        end

        after(:each) do
          File.delete(@tempfile)
        end

        it 'reads' do
          expect(stream.read).to eq(content)
        end

        it 'reads into a buffer' do
          expect(stream.read(len, outbuf)).to eq(content)
          expect(outbuf).to eq(content)
        end

        it 'reads n < length chars' do
          length = len/2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars'
        it 'reads n > length chars'
      end

      describe 'an array of strings' do
        it 'reads'
        it 'reads into a buffer'
        it 'reads n < length chars'
        it 'reads n == length chars'
        it 'reads n > length chars'
      end

      describe 'an array of files' do
        it 'reads'
        it 'reads into a buffer'
        it 'reads n < length chars'
        it 'reads n == length chars'
        it 'reads n > length chars'
      end

      describe 'a mix of strings and files' do
        it 'reads'
        it 'reads into a buffer'
        it 'reads n < length chars'
        it 'reads n == length chars'
        it 'reads n > length chars'
      end
    end
  end
end
