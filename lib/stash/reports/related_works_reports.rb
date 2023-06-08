# this require needed in tests, but not really in app, though it doesn't hurt anything
require_relative '../../../app/helpers/stash_engine/application_helper'

module Stash
  module Reports
    class RelatedWorksReports

      def self.datasets_without_journals
        count = 0
        ii = StashEngine::Identifier.where(pub_state: 'published')
        ii.each do |i|
          if i.publication_issn.blank?
            count += 1
            print "#{count} -- #{i.identifier} -- #{i.publication_issn}\n"
          end
        end     
      end
      
      def self.preprints_by_relation
        pp=StashDatacite::RelatedIdentifier.where(work_type: 'preprint')

        CSV.open('preprint_relations_report.csv', 'w') do |csv|
          csv << %w[ DataDOI Preprint HasPrimaryArticle Relations ]
          
          # for each, add their DOI to a dataset of                                                                                                                                            
          pp.each do |p|
            r = p.resource
            next unless r.identifier.present?
            
            has_primary = r.related_identifiers&.map(&:work_type)&.include?('primary_article')
            csv << [ r&.identifier&.identifier, p.related_identifier, has_primary, p.resource.related_identifiers.to_json ]
          end
        end
      end

    end
  end
end
