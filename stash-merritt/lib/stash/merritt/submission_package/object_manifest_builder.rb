require 'ostruct'
require 'stash/repo/file_builder'
require 'merritt'

module Stash
  module Merritt
    module SubmissionPackage
      class ObjectManifestBuilder < Stash::Repo::FileBuilder

        def system_dir
          Rails.public_path.join('system')
        end

      end
    end
  end
end
