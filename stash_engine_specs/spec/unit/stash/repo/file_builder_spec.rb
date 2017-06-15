require 'spec_helper'
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
          expect(builder.log).to be(logger)
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
          builder = FileBuilder.new(file_name: file_name)
          builder.define_singleton_method(:contents) { contents }
          Dir.mktmpdir do |target_dir|
            builder.write_file(target_dir)
            outfile = File.join(target_dir, file_name)
            expect(File.read(outfile)).to eq(contents)
          end
        end
        it 'appends a newline if needed' do
          file_name = 'contents.xml'
          builder = FileBuilder.new(file_name: file_name)
          builder.define_singleton_method(:contents) { 'elvis' }
          Dir.mktmpdir do |target_dir|
            builder.write_file(target_dir)
            outfile = File.join(target_dir, file_name)
            expect(File.read(outfile)).to eq("elvis\n")
          end
        end
        it 'doesn\'t append newlines to binary files' do
          file_name = 'contents.xml'
          builder = FileBuilder.new(file_name: file_name)
          builder.define_singleton_method(:binary?) { true }
          builder.define_singleton_method(:contents) { 'elvis' }
          Dir.mktmpdir do |target_dir|
            builder.write_file(target_dir)
            outfile = File.join(target_dir, file_name)
            expect(File.read(outfile)).to eq('elvis')
          end
        end
        it 'writes nothing if #contents returns nil' do
          builder = FileBuilder.new(file_name: 'contents.xml')
          builder.define_singleton_method(:contents) { nil }
          Dir.mktmpdir do |target_dir|
            builder.write_file(target_dir)
            expect(Dir.glob("#{target_dir}/*")).to be_empty
          end
        end
      end
    end
  end
end
