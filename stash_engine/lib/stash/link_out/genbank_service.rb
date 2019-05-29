# frozen_string_literal: true

require 'net/ftp'

require_relative 'helper'

module LinkOut

  # Every sequence record in NCBI databases with LinkOut capabilities that has an article as
  # reference (REFERENCE line in GenBank format) for which there is a data package in Dryad
  # should have a link out to the respective data package. Initially this may be restricted
  # to the nucleotide databases (and here to the NUCCORE database), which should, however,
  # be the most common use-case, and may also need to be restricted to sequences for those
  # articles that also have a DOI.
  class GenbankService

    include ::LinkOut::Helper

    def initialize
      make_linkout_dir!
      @ftp = APP_CONFIG.link_out.euro_pubmed_central
      @schema = 'http://europepmc.org/docs/labslink.xsd'.freeze
      @links_file = 'labslink-links.xml'.freeze
      @provider_file = 'labslink-profile.xml'.freeze
      @root_url = Rails.application.routes.url_helpers.root_url.freeze
    end

    def generate_files!
      p "  created #{generate_provider_file!}"
      p "  created #{generate_links_file!}"
    end

    def validate_files!

    end

    def publish_files!

    end

    private

    def generate_provider_file!

    end

    def generate_links_file!

    end

  end

end
