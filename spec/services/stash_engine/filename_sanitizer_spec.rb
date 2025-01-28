module StashEngine
  describe FilenameSanitizer do
    describe '.process' do
      subject { FilenameSanitizer.new(@file_name).process }

      it 'replaces illegal characters with the replacement character' do
        @file_name = 'inval|id:file*name?.txt'
        expect(subject).to eq('inval_id_file_name_.txt')
      end

      it 'removes control characters' do
        @file_name = "Hello\u0000World"
        expect(subject).to eq('Hello_World')
      end

      it 'truncates to 220 bytes' do
        @file_name = 'a' * 300
        expect(subject.bytesize).to eq(220)
      end

      %w[CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9].each do |reserved|
        it "replaces reserved filenames #{reserved} for Windows" do
          @file_name = "#{reserved}.txt"
          expect(subject).to eq('_')
        end
      end

      it 'removes trailing dots and spaces' do
        @file_name = 'filename. '
        expect(subject).to eq('filename_')
      end

      it 'sanitizes input with default replacement' do
        @file_name = 'invalid|name'
        expect(subject).to eq('invalid_name')
      end

      it 'allows customization of the replacement character' do
        file_name = 'invalid:name'
        output = FilenameSanitizer.new(file_name, replacement: '-').process
        expect(output).to eq('invalid-name')
      end

      it 'handles strings that are entirely illegal characters' do
        file_name = '|*?<>'
        output = FilenameSanitizer.new(file_name, replacement: '_').process
        expect(output).to eq('_____')
      end

      it 'handles strings that are entirely illegal characters' do
        @file_name = '[name]'
        expect(subject).to eq('_name_')
      end
    end

    describe '#truncate_utf8' do
      subject { FilenameSanitizer.new(@file_name) }

      it 'truncates a string to the specified byte limit' do
        @file_name = 'Hello, world!\u{1F600}' # String with an emoji
        truncated = subject.send(:truncate_utf8, @file_name, 10)
        expect(truncated.bytesize).to be <= 10
        expect(truncated).to eq('Hello, wor')
      end

      it 'handles multibyte characters gracefully' do
        @file_name = '你好世界'
        truncated = subject.send(:truncate_utf8, @file_name, 7)
        expect(truncated.bytesize).to be <= 7
        expect(truncated).to eq('你好') # Partial characters should not appear
      end
    end
  end
end
