require 'fileutils'
require 'tmpdir'
require 'stash_engine'
require 'stash_datacite'
require 'zip'
require 'datacite/mapping/datacite_xml_factory'
require 'stash/merritt/submission_package'

module Stash
  module Merritt
    class ZipPackage < SubmissionPackage

      attr_reader :zipfile

      def initialize(resource:)
        super(resource: resource, packaging: Stash::Sword::Packaging::SIMPLE_ZIP)
        @zipfile = create_zipfile
      end

      # returns the path to the payload
      def payload
        zipfile
      end

      def create_zipfile
        StashDatacite::PublicationYear.ensure_pub_year(resource)
        zipfile_path = File.join(workdir, "#{resource_id}_archive.zip")
        Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
          builders.each { |builder| write_to_zipfile(zipfile, builder) }
          new_uploads.each { |upload| add_to_zipfile(zipfile, upload) }
        end
        zipfile_path
      end

      def cleanup!
        return unless File.exist?(workdir)
        FileUtils.remove_dir(workdir)
        @zipfile = nil
      end

      def to_s
        "#{self.class}: zipfile submission package for resource #{resource_id} (#{resource_title}"
      end

      private

      def write_to_zipfile(zipfile, builder)
        return unless (file = builder.write_file(workdir))
        zipfile.add(builder.file_name, file)
      end

      def add_to_zipfile(zipfile, upload)
        path = File.join(resource.upload_dir, upload.upload_file_name)
        raise ArgumentError, "Upload file '#{upload.upload_file_name}' not found in directory #{resource.upload_dir}" unless File.exist?(path)
        zipfile.add(upload.upload_file_name, path)
      end

      def workdir
        @workdir ||= begin
          path = resource.upload_dir
          FileUtils.mkdir_p(path)
          tmpdir = Dir.mktmpdir('uploads', path)
          File.absolute_path(tmpdir)
        end
      end

    end
  end
end
