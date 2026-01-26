require 'csv'

module StashEngine
  # rubocop:disable Metrics/AbcSize, Metrics/ModuleLength, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  module AdminDashboardHelper
    def csv_report_head
      head = ['Title']
      head << 'DOI' if @fields.include?('doi')
      head << 'Keywords' if @fields.include?('keywords')
      head << 'Authors' if @fields.include?('authors')
      head << 'Emails' if @fields.include?('emails')
      if @fields.include?('affiliations') || @fields.include?('countries')
        head << (@fields.include?('affiliations') ? 'Affiliations' : 'Countries')
      end
      head << 'Submitter' if @fields.include?('submitter')
      head << 'Status' if @fields.include?('status')
      head << 'Size' if @fields.include?('size')
      head << 'Metrics' if @fields.include?('metrics')
      if @fields.include?('funders') || @fields.include?('awards')
        head << (@fields.include?('funders') ? 'Grant funders' : 'Award IDs')
      end
      head << 'Journal' if @fields.include?('journal')
      head << 'Journal sponsor' if @fields.include?('sponsor')
      head << 'Publication IDs' if @fields.include?('identifiers')
      head << 'Curator' if @fields.include?('curator')
      head << 'DPC paid by' if @fields.include?('dpc')
      head << 'Last modified' if @fields.include?('updated_at')
      head << 'Submitted' if @fields.include?('submit_date')
      head << 'First submitted' if @fields.include?('first_sub_date')
      head << 'Published' if @fields.include?('publication_date')
      head << 'First published' if @fields.include?('first_pub_date')
      head << 'First created' if @fields.include?('created_at')
      head << 'First queued' if @fields.include?('queue_date')
      head.to_csv(row_sep: "\r\n")
    end

    def csv_report_row(dataset)
      row = [dataset.title&.strip_tags]
      row << dataset.identifier.identifier if @fields.include?('doi')
      row << dataset.subjects.map(&:subject).join(', ') if @fields.include?('keywords')
      row << dataset.author_string if @fields.include?('authors')
      row << dataset.authors.limit(6).map(&:author_email).reject(&:blank?)&.join(', ') if @fields.include?('emails')
      if @fields.include?('affiliations') || @fields.include?('countries')
        uniq_affs = dataset.authors.map(&:affiliations).flatten.uniq
        ror_affs = uniq_affs.each_with_object([]) do |a, arr|
          arr << a if a.ror_id
          arr
        end
        affs = ror_affs.map do |aff|
          (
            [@fields.include?('affiliations') ? aff.smart_name : nil] +
            [@fields.include?('countries') ? aff.country_name : nil]
          ).reject(&:blank?).join(', ')
        end
        row << [if dataset.tenant_id == 'dryad'
                  nil
                else
                  (
                    [@fields.include?('affiliations') ? dataset.tenant&.short_name : nil] +
                    [@fields.include?('countries') ? dataset.tenant&.country_name : nil]
                  ).reject(&:blank?).join(', ')
                end].flatten.concat(affs).uniq.reject(&:blank?).first(6).join('; ')
      end
      if @fields.include?('submitter')
        row << "#{dataset.submitter&.first_name} #{dataset.submitter&.last_name}#{
          dataset.submitter.orcid.present? ? " ORCID: #{dataset.submitter.orcid}" : ''
        }"
      end
      row << StashEngine::CurationActivity.readable_status(dataset.last_curation_activity.status) if @fields.include?('status')
      row << filesize(dataset.total_file_size) if @fields.include?('size')
      if @fields.include?('metrics')
        c = dataset.identifier.counter_stat.unique_investigation_count
        r = dataset.identifier.counter_stat.unique_request_count
        views = c.blank? || c < r ? (r || 0) : c
        row << "#{views} views, #{r || 0} downloads, #{dataset.identifier.counter_stat.citation_count || 0} citations"
      end
      if @fields.include?('funders') || @fields.include?('awards')
        row << dataset.funders.map do |f|
          ([@fields.include?('funders') ? f.contributor_name : nil] + [@fields.include?('awards') ? f.award_number : nil]).reject(&:blank?).join(', ')
        end.uniq.reject(&:blank?).join('; ')
      end
      row << dataset.journal&.title if @fields.include?('journal')
      row << dataset.journal&.sponsor&.name if @fields.include?('sponsor')
      if @fields.include?('identifiers')
        mn = [dataset.resource_publication&.manuscript_number]
        related_ids = dataset.related_identifiers.map { |id| id.related_identifier.partition('//doi.org/').last }
        row << (mn + related_ids).reject(&:blank?).first(6).join(', ')
      end
      row << dataset.curator_name if @fields.include?('curator')
      if @fields.include?('dpc')
        dpc = ''
        dpc = dataset.tenant&.short_name if dataset.identifier.payment_id == dataset.tenant_id
        dpc = dataset.journal&.title if dataset.journal&.issn_array&.include?(dataset.identifier.payment_id)
        dpc = dataset.identifier.payment_id.split('funder:').last.split('|').first if dataset.identifier.payment_id&.starts_with?('funder')
        row << dpc
      end
      row << dataset.last_curation_activity.updated_at if @fields.include?('updated_at')
      row << (dataset.submitted_date) if @fields.include?('submit_date')
      if @fields.include?('first_sub_date')
        row << (dataset.identifier.process_date.processing || dataset.identifier.process_date.queued || dataset.identifier.process_date.peer_review)
      end
      row << dataset.publication_date if @fields.include?('publication_date')
      row << dataset.identifier.publication_date if @fields.include?('first_pub_date')
      row << dataset.identifier.created_at if @fields.include?('created_at')
      row << dataset.identifier.process_date.queued if @fields.include?('queue_date')
      row.to_csv(row_sep: "\r\n")
    end

    # rubocop:enable Metrics/AbcSize, Metrics/ModuleLength, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def csv_enumerator
      Enumerator.new do |rows|
        rows << csv_report_head
        @datasets.find_each do |d|
          rows << csv_report_row(d)
        end
      end
    end
  end
end
