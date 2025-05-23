# :nocov:
require 'csv'
require 'stash/organization/ror_updater'

# rubocop:disable Metrics/BlockLength
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Metrics/AbcSize
namespace :affiliation_import do

  root = Rails.root.join('/tmp').freeze

  desc 'Clean the long_names for all ROR affiliations'
  task clean_ror_names: :environment do
    StashDatacite::Affiliation.where.not(ror_id: nil).each do |affil|
      target_obj = StashEngine::RorOrg.find_by_ror_id(affil.ror_id)
      affil.update(long_name: target_obj.name) if target_obj
    end
  end

  desc 'Update ROR organizations in local database'
  task update_ror_orgs: :environment do
    Stash::Organization::RorUpdater.perform
  end

  desc 'Sync Affiliation name with ROR organizations name'
  task update_affiliations_names: :environment do
    Stash::Organization::AffiliationUpdater.perform
  end

  # example: RAILS_ENV=development bundle exec rake affiliation_import:process_ror_csv -- --affiliation_mode true
  desc 'Process all of the CSV files'
  task process_ror_csv: :environment do
    start_time = Time.now
    @dois_to_skip = []
    @live_mode = false
    @last_resource = nil
    args = Tasks::ArgsParser.parse(:affiliation_mode)

    case args.affiliation_mode
    when nil
      puts '--affiliation_mode argument is blank, assuming test mode.'
    when 'live'
      puts 'Starting live processing due to --affiliation_mode argument.'
      @live_mode = true
    else
      puts "--affiliation_mode argument is #{args.affiliation_mode}, entering test mode."
    end

    puts 'Loading affiliation info from CSV files in /tmp/dryad_affiliations*'

    Dir.entries(root).each do |f|
      next unless f.start_with?('dryad_affiliations')

      qualified_file_name = "#{root}/#{f}"
      puts "===== Processing file #{qualified_file_name} ====="
      process_file(file_name: qualified_file_name)
    end

    puts "DONE! Elapsed time: #{Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')}"
    exit
  end

  # example: RAILS_ENV=development bundle exec rake affiliation_import:merge_duplicate_authors -- --author_merge_mode true --start 0
  desc 'Merge duplicate authors'
  task merge_duplicate_authors: :environment do
    start_time = Time.now
    @live_mode = false
    args = Tasks::ArgsParser.parse(:author_merge_mode, :start)

    case args.author_merge_mode
    when nil
      puts '--author_merge_mode argument is blank, assuming test mode.'
    when 'live'
      puts 'Starting live processing due to --author_merge_mode argument.'
      @live_mode = true
    else
      puts "--author_merge_mode argument is #{args.author_merge_mode}, entering test mode."
    end

    start_from = 0
    start_from = args.start.to_i unless args.start.blank?

    stash_ids = StashEngine::Identifier.all.order('stash_engine_identifiers.id').distinct
    stash_ids.each_with_index do |i, idx|
      next if idx < start_from
      next unless i.latest_resource.present?

      puts "Processing #{idx + 1}/#{stash_ids.length}: #{i.identifier}"
      authors = i.latest_resource.authors
      (0..authors.size - 1).each do |a|
        (a + 1..authors.size - 1).each do |b|
          # see if the author has any potential duplicates
          next unless duplicates?(authors[a], authors[b])

          autha = authors[a].author_standard_name
          authb = authors[b].author_standard_name
          puts("DUPLICATES: |#{autha}|#{authb}|#{i.latest_resource.id}|" \
               "#{levenshtein_distance(autha, authb).to_f / [autha.size, authb.size].max}")
          if @live_mode
            do_author_merge(authors[a], authors[b])
            record_author_merge(resource: i.latest_resource)
          end
        end
      end
    end
    puts "DONE! Elapsed time: #{Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')}"
    exit
  end

  # example: rake affiliation_import:populate_ror_db -- --path /path/to/json_file
  desc 'Populate our ROR database manually from the ROR dump json file because the Zenodo API not working'
  task populate_ror_db: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f

    args = Tasks::ArgsParser.parse(:path)
    unless args.path
      puts 'Please enter the path to the ROR dump json file as an argument'
      puts 'You can get the latest dump from https://doi.org/10.5281/zenodo.6347574 (get json file for last version in zip)'
      exit
    end

    ror_dump_file = args.path
    exit unless File.exist?(ror_dump_file)

    Stash::Organization::RorUpdater.process_ror_json(json_file_path: ror_dump_file)
  end

  # example: rake affiliation_import:populate_funder_ror_mapping -- --path /path/to/json_file
  desc 'Populate fundref_id to ror_id mapping table'
  task populate_funder_ror_mapping: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f

    args = Tasks::ArgsParser.parse(:path)
    unless args.path
      puts 'Please enter the path to the ROR dump json file as an argument'
      puts 'You can get the latest dump from https://doi.org/10.5281/zenodo.6347574 (get json file for last version in zip)'
      exit
    end

    ror_dump_file = args.path
    exit unless File.exist?(ror_dump_file)

    ActiveRecord::Base.connection.truncate(StashEngine::XrefFunderToRor.table_name)
    fundref_ror_mapping = {}
    File.open(ror_dump_file, 'r') do |f|
      data = JSON.parse(f.read)
      data.each do |org|
        ror_id = org['id']
        name = org['name']
        fundref_ids = org.dig('external_ids', 'FundRef', 'all')
        next if fundref_ids.blank?

        fundref_ids.each do |fundref_id|
          fundref_ror_mapping[fundref_id] = { ror: ror_id, name: name }
        end
      end
    end

    to_insert = []
    fundref_ror_mapping.each_with_index do |(fundref_id, ror_info), index|
      to_insert << { xref_id: "http://dx.doi.org/10.13039/#{fundref_id}", ror_id: ror_info[:ror], org_name: ror_info[:name] }
      if index % 1000 == 0 && index > 0
        StashEngine::XrefFunderToRor.insert_all(to_insert)
        to_insert = []
      end
    end
    StashEngine::XrefFunderToRor.insert_all(to_insert) unless to_insert.empty?
    puts 'Done updating fundref to ror mapping table'
  end

  desc 'Populate NIH funders so they can be grouped under NIH umbrella organization'
  task populate_nih_ror_group: :environment do
    json = <<~JSON
      [
      	{
      		"identifier_type": "ror",
      		"contributor_name": "NIH Office of the Director",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00fj8a872"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Cancer Institute",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/040gcmg81"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Eye Institute",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/03wkg3b53"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Heart, Lung, and Blood Institute",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/012pb6c26"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Human Genome Research Institute",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00baak391"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute on Aging",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/049v75w11"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute on Alcohol Abuse and Alcoholism",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/02jzrsm59"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Allergy and Infectious Diseases",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/043z4tv69"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Arthritis and Musculoskeletal and Skin Diseases",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/006zn3t30"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Biomedical Imaging and Bioengineering",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00372qc85"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "Eunice Kennedy Shriver National Institute of Child Health and Human Development",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04byxyr05"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute on Deafness and Other Communication Disorders",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04mhx6838"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Dental and Craniofacial Research",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/004a2wv92"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Diabetes and Digestive and Kidney Diseases",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00adh9b73"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute on Drug Abuse",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00fq5cm18"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Environmental Health Sciences",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00j4k1h63"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of General Medical Sciences",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04q48ey07"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Mental Health",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04xeg9z08"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute on Minority Health and Health Disparities",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/0493hgw16"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Neurological Disorders and Stroke",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/01s5ya894"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Institute of Nursing Research",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/01y3zfr79"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "U.S. National Library of Medicine",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/0060t0j89"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "Center for Information Technology",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/03jh5a977"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "Center for Scientific Review",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04r5s4b52"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "Fogarty International Center",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/02xey9a22"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Center for Advancing Translational Sciences",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04pw6fb54"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "National Center for Complementary and Integrative Health",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/00190t495"
      	},
      	{
      		"identifier_type": "ror",
      		"contributor_name": "NIH Clinical Center",
      		"contributor_type": "funder",
      		"name_identifier_id": "https://ror.org/04vfsmv21"
      	}
      ]
    JSON

    json = JSON.parse(json)

    StashDatacite::ContributorGrouping.destroy_by(name_identifier_id: 'https://ror.org/01cwqze88') # nih umbrella org
    StashDatacite::ContributorGrouping.create!(contributor_name: 'National Institutes of Health',
                                               contributor_type: 'funder',
                                               identifier_type: 'ror',
                                               name_identifier_id: 'https://ror.org/01cwqze88',
                                               group_label: 'NIH Directorate',
                                               json_contains: json)
  end

  def do_author_merge(a1, a2)
    # keep the text of the name that is longest, but
    # keep the affiliation for the author that was updated most recently
    target_first = a1.author_first_name
    target_last = a1.author_last_name
    if a1.author_standard_name.size < a2.author_standard_name.size
      target_first = a2.author_first_name
      target_last = a2.author_last_name
    end
    target_affil = (a1.updated_at > a2.updated_at ? a1.affiliation : a2.affiliation)
    target_email = (a1.author_email.present? ? a1.author_email : a2.author_email)
    target_orcid = (a1.author_orcid.present? ? a1.author_orcid : a2.author_orcid)

    a1.author_first_name = target_first
    a1.author_last_name = target_last
    a1.affiliation = target_affil
    a1.author_email = target_email
    a1.author_orcid = target_orcid
    a1.save
    a2.destroy
  end

  def duplicates?(author1, author2)
    # To prevent names with repeated initials (Molly Mason) from over-matching,
    # if distance is >= 0.5, must have all of their initials the same before doing the normal tests
    a1_std = author1.author_standard_name
    a2_std = author2.author_standard_name
    string_difference = levenshtein_distance(a1_std, a2_std).to_f / [a1_std.size, a2_std.size].max
    if string_difference >= 0.5
      a1_initials = "#{author1.author_first_name} #{author1.author_last_name}".split.map { |part| part[0].downcase }.join(' ')
      a2_initials = "#{author2.author_first_name} #{author2.author_last_name}".split.map { |part| part[0].downcase }.join(' ')
      return false unless a1_initials == a2_initials
    end

    a1 = "#{author1.author_first_name} #{author1.author_last_name}".downcase.split
    a2 = "#{author2.author_first_name} #{author2.author_last_name}".downcase.split

    # ensure a1 is the author with the most parts in their name (otherwise a single-part name would match almost anything)
    a1, a2 = a2, a1 if a1.size < a2.size

    # iterate through each part of the string
    a1.each_with_index do |a1part, index|
      # if this part matches (same or initial), move to the next section
      next if author_part_matches?(a1part, a2[index])
      # if the corresponding part doesn't match, see if the next/previous section matches,
      # because many differences are the addition/deletion of a middle initial.
      next if author_part_matches?(a1part, a2[index + 1])
      next if (index > 0) && author_part_matches?(a1part, a2[index - 1])

      # if none of the above matched, the authors are not matches
      return false
    end
    # if we checked the entire string, the authors are duplicates
    true
  end

  def author_part_matches?(s1, s2)
    return true if s1 == s2
    return false if s1.blank? || s2.blank?

    # true if s1 is an initial of s2
    return true if s1.size == 1 && s1 == s2[0]
    return true if s1.size == 2 && s1[1] == '.' && s1[0] == s2[0]

    # true if s2 is an initial of s1
    return true if s2.size == 1 && s2 == s1[0]
    return true if s2.size == 2 && s2[1] == '.' && s2[0] == s1[0]

    # if the two strings are neither the same nor an initial of each other, they don't match
    false
  end

  # levenshtein_distance from https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0

    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i - 1] == t[j - 1] # adjust index into string
                    d[i - 1][j - 1]       # no operation required
                  else
                    [d[i - 1][j] + 1, # deletion
                     d[i][j - 1] + 1, # insertion
                     d[i - 1][j - 1] + 1].min
                  end
      end
    end
    d[m][n]
  end

  def process_file(file_name:)
    CSV.foreach(file_name) do |entry|
      # puts "<< #{entry} >>"
      next if entry[0] == 'DOI' && entry[1] == 'person' # header row

      doi, person, organization, ror_original, ror, identifier_date, supplement_to,
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

    # start with the assuption that the firstname lastname split is at the first space, but
    # if that doesn't match an author on this item, try successive spaces
    parts = name.split
    author = nil
    (1..parts.size).each do |space_to_try|
      first = parts[0..space_to_try - 1].join(' ')
      last = parts[space_to_try..].join(' ')
      puts "  searching authors for resource #{resource.id}, first[#{first}], last[#{last}]"
      author = StashEngine::Author.where('stash_engine_authors.resource_id = ? ' \
                                         'AND LOWER(stash_engine_authors.author_last_name) = ? ' \
                                         'AND LOWER(stash_engine_authors.author_first_name) = ?', resource.id, last, first).first
      break if author
    end

    puts "    WARNING! AUTHOR NOT FOUND!! #{name}" if author.blank?
    record_affiliation_update(resource: resource) if @live_mode
    handle_affiliation(author: author, ror: ror, org_name: org_name)
  end

  def record_affiliation_update(resource:)
    return if resource.blank? || resource.curation_activities.blank?
    return if resource.id == @last_resource&.id

    resource.curation_activities << StashEngine::CurationActivity.create(user_id: 0,
                                                                         note: 'Author affiliations updated by affiliation_import:process_ror_csv',
                                                                         status: resource.curation_activities.last.status)
    @last_resource = resource
  end

  def record_author_merge(resource:)
    return if resource.blank? || resource.curation_activities.blank?
    return if resource.id == @last_resource&.id

    resource.curation_activities << StashEngine::CurationActivity.create(user_id: 0,
                                                                         note: 'Duplicate authors combined by ' \
                                                                               'affiliation_import:merge_duplicate_authors',
                                                                         status: resource.curation_activities.last.status)
    @last_resource = resource
  end

  def handle_affiliation(author:, ror:, org_name:)
    return nil unless author.present? && org_name.present?

    if author.affiliations.present? && author.affiliations.size > 1
      puts "    Skipping author with multiple affiliations. author_id=#{author.id}"
      return
    end

    if author.resource.blank? || author.resource.publication_date.blank?
      puts "    WARNING! Skipping author with blank publication date. author_id=#{author.id}"
      return
    end

    dryad_v2_launch_date = Date.parse('2019-9-17')
    if author.resource.publication_date >= dryad_v2_launch_date
      puts "    Skipping post-lauch item; assuming its affiliations are correct resource_id=#{author.resource}"
      return
    end

    if author.affiliations.present? && ror.blank?
      puts "    Author already has affiliation, and input file has no ROR. author_id=#{author.id}"
      return
    end

    # If we have gotten through all of the above checks, we can safely replace any
    # existing affiliation with a "better" affiliation from the input file
    target_affiliation = if ror.present?
                           StashDatacite::Affiliation.from_ror_id(ror_id: ror)
                         else
                           StashDatacite::Affiliation.from_long_name(long_name: org_name)
                         end
    puts "    Assigning affiliation: #{target_affiliation.long_name} --> #{target_affiliation.ror_id}"
    return unless @live_mode

    author.affiliation = target_affiliation
    author.save
  end
end
# rubocop:enable Metrics/BlockLength

# rubocop:enable Lint/UselessAssignment
# rubocop:enable Metrics/AbcSize
# :nocov:
