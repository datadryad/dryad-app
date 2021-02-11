require 'fileutils'
require 'mime-types'
require 'stash/aws/s3'

module Stash
  module Repo
    class FileBuilder
      def log
        Rails.logger
      end

      # @param file_name [String] the default file name, or nil if overriding #file_name
      def initialize(file_name: nil)
        @file_name = file_name
      end

      # Override to provide the name of the file to write to. Can include subdirectories, if appropriate.
      # The default implementation returns #file_name.
      #
      # @return [String] the filename
      def file_name
        return @file_name if @file_name

        raise NoMethodError, "#{self.class} should either provide :file_name in the initializer, or override #file_name; but it doesn't"
      end

      # Override to provide the contents of the file.
      # @return [String, nil] the contents, or nil if the file should not be written.
      def contents
        raise NoMethodError, "#{self.class} should override #file_contents to build a file, but it doesn't"
      end

      # Override to provide the MIME type of the file.
      # @return [MIME::Type] the MIME type of the file
      def mime_type
        raise NoMethodError, "#{self.class} should override #mime_type to return the MIME type, but it doesn't"
      end

      # Whether the file is binary. Defaults to false.
      # @return [boolean] true if the file should be written as binary, false otherwise.
      def binary?
        false
      end

      # Writes the file to the specified directory, assuming `contents` is non-nil.
      # @param target_dir [String] the directory to write the file into
      # @return [String, nil] the path to the created file, or nil if no file was created
      #   (i.e. if `contents` was nil)
      def write_local_file(target_dir)
        file_contents = contents
        return unless file_contents

        outfile = File.join(target_dir, file_name)
        FileUtils.mkdir_p(File.dirname(outfile))
        mode = binary? ? 'wb' : 'w'
        File.open(outfile, mode) do |f|
          f.write(file_contents)
          f.write("\n") unless binary? || file_contents.end_with?("\n")
        end
        outfile
      end

      # Writes the file to the target_dir in S3, and
      # returns the key for the file
      def write_s3_file(target_dir)
        puts "XXXX -- saving #{file_name} to S3 in #{APP_CONFIG[:s3][:bucket]} -- #{target_dir}"

        puts 'XXX fb wsf a'
        file_contents = contents
        return unless file_contents

        puts 'XXX fb wsf b'
        file_path = "#{target_dir}/#{file_name}"
        path_out = Stash::Aws::S3.write_to_s3(file_path: file_path,
                                              contents: file_contents)
        puts "XXXXXXXXXX wrote #{file_path} XXXXXXXXXXXXXXXXXXXXX"
        file_path
      end
    end
  end
end
