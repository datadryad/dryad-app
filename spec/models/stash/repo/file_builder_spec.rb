require 'tmpdir'

module Stash
  module Repo
    describe FileBuilder do
      describe :file_name do
        it 'defaults to the value provided in the initializer' do
          file_name = 'qux.txt'
          builder = FileBuilder.new(file_name: file_name)
          expect(builder.file_name).to eq(file_name)
        end
        it 'requires a filename' do
          builder = FileBuilder.new
          expect { builder.file_name }.to raise_error(NoMethodError)
        end
        it 'can be overridden' do
          builder = FileBuilder.new
          file_name = 'qux.txt'
          builder.define_singleton_method(:file_name) { file_name }
          expect(builder.file_name).to eq(file_name)
        end
      end

      describe :log do
        it 'returns the Rails logger' do
          logger = instance_double(Logger)
          allow(Rails).to receive(:logger).and_return(logger)
          builder = FileBuilder.new
          expect(builder.logger).to be(logger)
        end
      end

      describe :contents do
        it 'is abstract' do
          builder = FileBuilder.new(file_name: 'qux.txt')
          expect { builder.contents }.to raise_error(NoMethodError)
        end
      end

      describe :mime_type do
        it 'is abstract' do
          builder = FileBuilder.new(file_name: 'qux.txt')
          expect { builder.mime_type }.to raise_error(NoMethodError)
        end
      end

      describe :binary? do
        it 'defaults to false' do
          builder = FileBuilder.new(file_name: 'qux.txt')
          expect(builder.binary?).to be false
        end
      end

      describe :write_file do
        it 'writes the file' do
          contents = "<contents/>\n"
          file_name = 'contents.xml'
          target_dir = 'some/bogus/target_dir'
          builder = FileBuilder.new(file_name: file_name)
          builder.define_singleton_method(:contents) { contents }
          expect_any_instance_of(Stash::Aws::S3).to receive(:put)
            .with(s3_key: "#{target_dir}/#{file_name}",
                  contents: contents)
            .at_least(:once)
          builder.write_s3_file(target_dir)
        end

        it 'writes nothing if #contents returns nil' do
          file_name = 'contents.xml'
          target_dir = 'some/bogus/target_dir'
          builder = FileBuilder.new(file_name: file_name)
          expect_any_instance_of(Stash::Aws::S3).not_to receive(:put)
          builder.define_singleton_method(:contents) { nil }
          builder.write_s3_file(target_dir)
        end
      end
    end
  end
end
