require_relative 'related_identifiers/replacements'

namespace :related_identifiers do

  desc 'update all the DOIs I can into correct format (in separate field)'
  task fix_common_doi_problems: :environment do
    Tasks::RelatedIdentifiers::Replacements.update_doi_prefix
    Tasks::RelatedIdentifiers::Replacements.update_bare_doi
    Tasks::RelatedIdentifiers::Replacements.move_good_format
    Tasks::RelatedIdentifiers::Replacements.update_http_good
    Tasks::RelatedIdentifiers::Replacements.update_http_dx_doi
    Tasks::RelatedIdentifiers::Replacements.update_protocol_free
    Tasks::RelatedIdentifiers::Replacements.update_non_ascii
    Tasks::RelatedIdentifiers::Replacements.remaining_strings_containing_dois
  end
end
