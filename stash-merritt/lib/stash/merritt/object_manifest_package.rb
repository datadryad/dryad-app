require 'fileutils'
require 'tmpdir'
require 'stash_engine'
require 'stash_datacite'
require 'datacite/mapping/datacite_xml_factory'
require 'stash/merritt/submission_package'

module Stash
  module Merritt
    class ObjectManifestPackage
      include SubmissionPackage

    end
  end
end
