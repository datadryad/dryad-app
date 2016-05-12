require 'spec_helper'
require 'tempfile'

module Stash
  module Sword2

    # TODO: refactor with shared examples
    describe ArrayStream do

      ALPHANUMERIC = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')

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
          @content = Array.new(len) { ALPHANUMERIC.sample }.join
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
          length = len / 2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars' do
          expect(stream.read(len)).to eq(content)
        end

        it 'reads n > length chars' do
          expect(stream.read(len * 2)).to eq(content)
        end

        it 'calculates the size' do
          expect(stream.size).to eq(len)
        end
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
          length = len / 2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars' do
          expect(stream.read(len)).to eq(content)
        end

        it 'reads n > length chars' do
          expect(stream.read(len * 2)).to eq(content)
        end

        it 'calculates the size' do
          expect(stream.size).to eq(len)
        end
      end

      describe 'an array of strings' do

        before(:each) do
          @len = 100
          @inputs = Array.new(10) { Array.new(10) { ALPHANUMERIC.sample }.join }
          @content = @inputs.join
          @stream = ArrayStream.new(@inputs)
        end

        it 'reads' do
          expect(stream.read).to eq(content)
        end

        it 'reads into a buffer' do
          expect(stream.read(len, outbuf)).to eq(content)
          expect(outbuf).to eq(content)
        end

        it 'reads n < length chars' do
          length = len / 2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars' do
          expect(stream.read(len)).to eq(content)
        end

        it 'reads n > length chars' do
          expect(stream.read(len * 2)).to eq(content)
        end

        it 'calculates the size' do
          expect(stream.size).to eq(len)
        end
      end

      describe 'an array of files' do

        before(:each) do
          @len = 100
          @content = ''
          @tempfiles = Array.new(10) do |i|
            f = Tempfile.new(%W(array_stream-spec-#{i} bin))
            f.binmode
            begin
              content = Random.new.bytes(10)
              @content << content
              f.write(content)
            ensure
              f.close
            end
            f.path
          end
          @inputs = @tempfiles.map { |f| File.open(f, 'rb') }
          @stream = ArrayStream.new(inputs)
        end

        after(:each) do
          @tempfiles.each { |f| File.delete(f) }
        end

        it 'reads' do
          expect(stream.read).to eq(content)
        end

        it 'reads into a buffer' do
          expect(stream.read(len, outbuf)).to eq(content)
          expect(outbuf).to eq(content)
        end

        it 'reads n < length chars' do
          length = len / 2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars' do
          expect(stream.read(len)).to eq(content)
        end

        it 'reads n > length chars' do
          expect(stream.read(len * 2)).to eq(content)
        end

        it 'calculates the size' do
          expect(stream.size).to eq(len)
        end
      end

      describe 'a mix of strings and files' do

        before(:each) do
          @len = 100
          @content = ''

          strings = Array.new(5) { Array.new(10) { ALPHANUMERIC.sample }.join }

          file_contents = []
          @tempfiles = Array.new(5) do |i|
            f = Tempfile.new(%W(array_stream-spec-#{i} bin))
            f.binmode
            begin
              content = Random.new.bytes(10)
              file_contents << content
              f.write(content)
            ensure
              f.close
            end
            f.path
          end

          @inputs = (0..9).map do |i|
            index = i / 2
            if i.even?
              @content << file_contents[index]
              File.open(@tempfiles[index], 'rb')
            else
              @content << strings[index]
              strings[index]
            end
          end

          @stream = ArrayStream.new(inputs)
        end

        after(:each) do
          @tempfiles.each { |f| File.delete(f) }
        end

        it 'reads' do
          expect(stream.read).to eq(content)
        end

        it 'reads into a buffer' do
          expect(stream.read(len, outbuf)).to eq(content)
          expect(outbuf).to eq(content)
        end

        it 'reads n < length chars' do
          length = len / 2
          expected = content.slice(0, length)
          expect(stream.read(length, outbuf)).to eq(expected)
          expect(outbuf).to eq(expected)
        end

        it 'reads n == length chars' do
          expect(stream.read(len)).to eq(content)
        end

        it 'reads n > length chars' do
          expect(stream.read(len * 2)).to eq(content)
        end

        it 'calculates the size' do
          expect(stream.size).to eq(len)
        end
      end
    end
  end
end
