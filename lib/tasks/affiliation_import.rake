require 'csv'

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Lint/UselessAssignment
namespace :affiliation_import do

  ROOT = Rails.root.join('/tmp').freeze

  desc 'Process all of the TSV files'
  task process_ror_csv: :environment do
    start_time = Time.now
    @dois_to_skip = []
    @live_mode = false

    case ENV['AFFILIATION_MODE']
    when nil
      puts 'Environment variable AFFILIATION_MODE is blank, assuming test mode.'
    when 'live'
      puts 'Starting live processing due to environment variable AFFILIATION_MODE.'
      @live_mode = true
    else
      puts "Environment variable AFFILIATION_MODE is #{ENV['AFFILIATION_MODE']}, entering test mode."
    end

    puts 'Loading affiliation info from CSV files in /tmp/dryad_affiliations*'

    Dir.entries(ROOT).each do |f|
      next unless f.start_with?('dryad_affiliations')
      qualified_file_name = "#{ROOT}/#{f}"
      puts "===== Processing file #{qualified_file_name} ====="
      process_file(file_name: qualified_file_name)
    end

    puts "DONE! Elapsed time: #{Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')}"
  end

  def process_file(file_name:)
    CSV.foreach(file_name) do |entry|
      # puts "<< #{entry} >>"
      next if entry[0] == 'DOI' && entry[1] == 'person' # header row

      doi, person, organization, ror_original, ror, identifier_date, supplement_to, \
      publication_date, title, type, update_date, organization_date = entry

      next if @dois_to_skip.include?(doi)
      next unless doi.present?
      identifier = StashEngine::Identifier.where(identifier: doi).first
      @dois_to_skip << doi unless identifier.present?
      puts "****** NO DATASET FOUND WITH ID: #{doi} -- #{title}" unless identifier.present?
      next unless identifier.present?
      next unless identifier.latest_resource.present?
      puts "Processing #{identifier} #{title}"
      handle_author(resource: identifier.latest_resource, name: person, ror: ror, org_name: organization)
    end
  end

  def handle_author(resource:, name:, ror:, org_name:)
    return nil unless resource.present? && name.present?

    # start with the assuption that the firstname lastname split is at the first space
    parts = name.split(' ')
    first = parts[0]
    last = parts[1..-1].join(' ')
    puts "  searching authors for resource #{resource.id}, first[#{first}], last[#{last}]"
    author = StashEngine::Author.where('stash_engine_authors.resource_id = ? ' \
                                       'AND LOWER(stash_engine_authors.author_last_name) = ? ' \
                                       'AND LOWER(stash_engine_authors.author_first_name) = ?', resource.id, last, first).first

    if author.nil? && parts.size > 2
      # try split at second space, see if we find an author that way
      first = parts[0..1].join(' ')
      last = parts[2..-1].join(' ')
      puts "  searching authors for resource #{resource.id}, first[#{first}], last[#{last}]"
      author = StashEngine::Author.where('stash_engine_authors.resource_id = ? ' \
                                         'AND LOWER(stash_engine_authors.author_last_name) = ? ' \
                                         'AND LOWER(stash_engine_authors.author_first_name) = ?', resource.id, last, first).first
    end

    if author.blank?
      puts "    WARNING! AUTHOR NOT FOUND!! #{last}, #{first}"
      if @live_mode
        # author = StashEngine::Author.new(resource_id: resource.id, author_last_name: last, author_first_name: first)
        # author.save
      end
    end
    handle_affiliation(author: author, ror: ror, org_name: org_name)
  end

  def handle_affiliation(author:, ror:, org_name:)
    return nil unless author.present? && org_name.present?

    if author.affiliations.present? && author.affiliations.size > 1
      puts "    WARNING! Skipping author with multiple affiliations. author_id=#{author.id}"
      return
    end

    if author.resource.blank? || author.resource.publication_date.blank?
      puts "    WARNING! Skipping author with blank publication date. author_id=#{author.id}"
      return
    end

    dryad_v2_launch_date = Date.parse('2019-9-17')
    if author.resource.publication_date >= dryad_v2_launch_date
      puts "    skipping post-lauch item; assuming its affiliations are correct resource_id=#{author.resource}"
      return
    end

    if author.affiliations.present? && ror.blank?
      puts "    WARNING! Author already has affiliation, and input file has no ROR. author_id=#{author.id}"
      return
    end

    # If we have gotten through all of the above checks, we can safely replace any
    # existing affiliation with a "better" affiliation from the input file
    target_affiliation = StashDatacite::Affiliation.find_or_initialize_by(long_name: org_name, ror_id: ror)
    puts "    Assigning affiliation: #{target_affiliation.long_name} --> #{target_affiliation.ror_id}"

    return unless @live_mode
    author.affiliation = target_affiliation
    author.save
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Lint/UselessAssignment
