# Emgargo fix tool -- correct overly-conservative embargoes that were put in place by migration
# See ticket https://github.com/CDL-Dryad/dryad-product-roadmap/issues/400
# :nocov:
namespace :embargo_fix do

  desc 'Embargo manipulation to correct the problem of conservative embargoes from migration'
  task migration_issue: :environment do
    p 'Starting embargo correction'
    File.readlines('/apps/dryad/embargoIssues.txt').each do |line|
      line.gsub!('doi:', '')
      line.gsub!(/\s+/, '')
      p "Processing #{line}"

      is = StashEngine::Identifier.where(identifier: line)
      next if is.empty?

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
            next unless notestring

            if /package-level embargo to reflect previous file-level/.match?(notestring)
              p '      - ######### EMBARGO INDICATOR ##############'
              embargo_indicator = ca
            end
          end

          # re-process the curation activities from the beginning
          # if a fix is needed, find the publish date, set it, and
          # update all subsequent curation activities to be 'published'
          next unless embargo_indicator

          embargo_indicator.destroy # remove the indicator CurationActivity
          embargo_indicator = nil

          cas = r.curation_activities # reload the CurationActivities without the indicator

          cas.order(:id).each do |ca|
            p "      - ca #{ca&.id} #{ca&.created_at} #{ca.note[0..30]}"
            if ca&.note&.match(/Made available in DSpace on/)
              p "      - ######### PUBLISH DATE #{ca&.created_at} ##############"
              r.publication_date = ca&.created_at
              r.save
              @publishing = true
            end

            next unless @publishing

            p '      - updating to published'
            if ca&.note&.match(/publiction date has not yet been reached/)
              ca.destroy
            else
              ca.status = 'published'
              ca.save
            end
          end
          @publishing = false
        end
      end
    end
    p 'Finished embargo correction'
  end

  desc 'Embargo manipulation to correct problems caused by Embargo Datasets CRON'
  task cron_issue: :environment do
    p 'Starting embargo CRON correction'
    File.readlines('/apps/dryad/embargoIssues.txt').each do |line|
      line.gsub!('doi:', '')
      line.gsub!(/\s+/, '')
      p "Processing #{line}"

      is = StashEngine::Identifier.where(identifier: line)
      next if is.empty?

      p "- found #{is.size} identifiers for #{line}"
      is.each do |i|
        p "  - identifier #{i.id} #{i&.identifier}"
        rs = i.resources
        rs.each do |r|
          embargo_indicator = nil
          published_indicator = nil
          publishing = false
          p "    - resource #{r.id}"
          cas = r.curation_activities

          # verify that the embargo was set incorrectly for this item  and that it hasn't been fixed yet
          cas.order(:id).each do |ca|
            notestring = ca&.note
            p "      - ca #{ca&.id} #{ca&.created_at} #{notestring}"
            next unless notestring

            if /Embargo Datasets CRON - publication date has not yet been reached/.match?(notestring)
              p '      - ######### EMBARGO INDICATOR ##############'
              embargo_indicator = ca
            end
            if /Made available in DSpace on/.match?(notestring)
              p '      - ######### PUBLISHED INDICATOR ##############'
              published_indicator = ca
            end
          end

          # If there is both an embargo_indicator and a published_indicator,
          # remove the erroneous embargo_indicator
          next unless embargo_indicator && published_indicator

          embargo_indicator.destroy # remove the indicator CurationActivity
          embargo_indicator = nil

          # Re-process the curation activities from the beginning.
          # If a fix is needed, find the publish date, set it, and
          # update all subsequent curation activities to be 'published'
          cas = r.curation_activities # reload the CurationActivities without the indicator

          cas.order(:id).each do |ca|
            p "      - ca #{ca&.id} #{ca&.created_at} #{ca.note[0..30]}"
            if ca&.note&.match(/Made available in DSpace on/)
              p "      - ######### PUBLISH DATE #{ca&.created_at} ##############"
              r.publication_date = ca&.created_at
              r.save
              publishing = true
            end

            next unless publishing

            p '      - updating to published'
            if ca&.note&.match(/publiction date has not yet been reached/)
              ca.destroy
            else
              ca.status = 'published'
              ca.save
            end
          end
          publishing = false
        end
      end
    end
    p 'Finished embargo correction'
  end
end
# :nocov:
