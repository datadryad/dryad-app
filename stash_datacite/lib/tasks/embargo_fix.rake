require 'stash/import/crossref'

# Emgargo fix tool -- correct overly-conservative embargoes that were put in place by migration
# See ticket https://github.com/CDL-Dryad/dryad-product-roadmap/issues/400
# rubocop:disable Metrics/BlockLength
namespace :embargo_fix do

  desc 'Do some embargo manipulation'
  task do_it: :environment do
    p 'Starting embargo correction'
    embargo_problem_items = File.readlines("/apps/dryad/embargoIssues.txt").each do |line|
      line.gsub!(/doi:/, "")
      line.gsub!(/\s+/, '')
      p "Processing #{line}"

      is = StashEngine::Identifier.where(identifier: line)
      if is.size > 0        
        p "- found #{is.size} identifiers for #{line}"
        is.each do |i|
          p "  - identifier #{i.id} #{i&.identifier}"
          rs = i.resources
          rs.each do |r|
            embargo_indicator = nil
            @publishing = false
            p "    - resource #{r.id}"
            cas = r.curation_activities

            # verify that the embargo was set incorrectly for this item  and that it hasn't been fixed yet
            cas.order(:id).each do |ca|
              notestring = ca&.note
              p "      - ca #{ca&.id} #{ca&.created_at} #{notestring}"
              if notestring                
                if notestring.match /package-level embargo to reflect previous file-level/
                  p "      - ######### EMBARGO INDICATOR ##############"
                  embargo_indicator = ca
                end
              end
            end

            # re-process the curation activities from the beginning
            # if a fix is needed, find the publish date, set it, and
            # update all subsequent curation activities to be 'published'
            if embargo_indicator
              embargo_indicator.destroy # remove the indicator CurationActivity
              embargo_indicator = nil
              
              cas = r.curation_activities # reload the CurationActivities without the indicator
                           
              cas.order(:id).each do |ca|
                p "      - ca #{ca&.id} #{ca&.created_at} #{ca&.note[0..30]}"
                if ca&.note&.match /Made available in DSpace on/
                  p "      - ######### PUBLISH DATE #{ca&.created_at} ##############"
                  r.publication_date = ca&.created_at
                  r.save
                  @publishing = true
                end
                
                if @publishing
                  p "      - updating to published"
                  if ca&.note&.match /publiction date has not yet been reached/
                    ca.destroy
                  else
                    ca.status = 'published'
                    ca.save
                  end
                end
              end
              @publishing = false
            end
          end            
        end
      end
    end
    p 'Finished embargo correction'
  end

end
# rubocop:enable Metrics/BlockLength
