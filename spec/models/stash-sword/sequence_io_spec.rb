require 'tempfile'

module Stash
  module Sword

    RSpec.shared_examples 'reading' do
      it 'reads' do
        expect(sqio.read).to eq(content)
      end

      it 'reads into a buffer' do
        expect(sqio.read(len, outbuf)).to eq(content)
        expect(outbuf).to eq(content)
      end

      it 'reads n < length chars' do
        length   = len / 2
        expected = content.slice(0, length)
        expect(sqio.read(length)).to eq(expected)
      end

      it 'reads n < length chars into a buffer' do
        length   = len / 2
        expected = content.slice(0, length)
        expect(sqio.read(length, outbuf)).to eq(expected)
        expect(outbuf).to eq(expected)
      end

      it 'reads n == length chars' do
        expect(sqio.read(len)).to eq(content)
      end

      it 'reads n == length chars into a buffer' do
        expect(sqio.read(len, outbuf)).to eq(content)
        expect(outbuf).to eq(content)
      end

      it 'reads n > length chars' do
        expect(sqio.read(len * 2)).to eq(content)
      end

      it 'reads n > length chars into a buffer' do
        expect(sqio.read(len * 2, outbuf)).to eq(content)
        expect(outbuf).to eq(content)
      end

      it 'calculates the size' do
        expect(sqio.size).to eq(len)
      end
    end

    describe SequenceIO do

      ALPHANUMERIC = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')

      attr_reader :len
      attr_reader :content
      attr_reader :sqio
      attr_reader :outbuf
      attr_reader :tempfiles

      before(:each) do
        @len    = 100
        @outbuf = '[overwrite me!]'
      end

      after(:each) do
        sqio.close if sqio
        tempfiles.each { |f| FileUtils.rm_f(f) } if tempfiles
      end

      def make_alphanumeric_string(chars)
        Array.new(chars) { ALPHANUMERIC.sample }.join
      end

      def make_tempfile(base_name, content)
        f = Tempfile.new([base_name, 'bin'])
        f.binmode
        begin
          f.write(content)
        ensure
          f.close
        end
        f.path
      end

      describe 'a string' do
        before(:each) do
          @content = make_alphanumeric_string(len)
          @sqio    = SequenceIO.new(@content)
        end
        include_examples 'reading'
      end

      describe 'a file' do
        before(:each) do
          @content   = Random.new.bytes(len)
          @tempfiles = [make_tempfile('array_stream-spec', content)]
          @sqio      = SequenceIO.new(File.open(tempfiles[0], 'rb'))
        end
        include_examples 'reading'
      end

      describe 'an array of strings' do
        before(:each) do
          inputs   = Array.new(10) { make_alphanumeric_string(10) }
          @content = inputs.join
          @sqio    = SequenceIO.new(inputs)
        end
        include_examples 'reading'
      end

      describe 'an array of files' do
        before(:each) do
          @content   = ''
          @tempfiles = Array.new(10) do |i|
            content = Random.new.bytes(10)
            @content << content
            make_tempfile("array_stream-spec-#{i}", content)
          end
          @sqio      = SequenceIO.new(@tempfiles.map { |f| File.open(f, 'rb') })
        end
        include_examples 'reading'
      end

      describe 'a mix of strings and files' do
        before(:each) do
          @content   = ''
          @tempfiles = []
          inputs     = (0..9).map do |i|
            content = nil
            begin
              if i.even?
                content = make_alphanumeric_string(10)
              else
                content = Random.new.bytes(10)
                @tempfiles << make_tempfile("array_stream-spec-#{i}", content)
                File.open(tempfiles.last, 'rb')
              end
            ensure
              @content << content
            end
          end

          @sqio = SequenceIO.new(inputs)
        end

        include_examples 'reading'
      end
    end
  end
end
