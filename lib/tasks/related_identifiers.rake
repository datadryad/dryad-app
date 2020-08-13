require_relative 'related_identifiers/replacements'

namespace :related_identifiers do

  desc 'update all the DOIs I can into correct format (in separate field)'
  task fix_common_doi_problems: :environment do
    RelatedIdentifiers::Replacements.update_doi_prefix
    RelatedIdentifiers::Replacements.update_bare_doi
    RelatedIdentifiers::Replacements.move_good_format
    RelatedIdentifiers::Replacements.update_http_good
    RelatedIdentifiers::Replacements.update_http_dx_doi
    RelatedIdentifiers::Replacements.update_protocol_free
    RelatedIdentifiers::Replacements.update_non_ascii
    RelatedIdentifiers::Replacements.remaining_strings_containing_dois
  end
end
