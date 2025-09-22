require 'csv'

class AuthorsService
  attr_reader :author

  def initialize(author = nil)
    @author = author
  end

  def check_orcid
    return if author.blank?
    return if author.author_email.blank?
    return if author.author_orcid.present?

    orcid = nil
    # check User model first
    record = StashEngine::User.where('LOWER(email) = LOWER(?)', author.author_email).where.not(orcid: [nil, '']).first
    orcid = record.orcid if record

    if orcid.blank?
      # check Author model
      record = StashEngine::Author.where('LOWER(author_email) = LOWER(?)', author.author_email).where.not(author_orcid: [nil, '']).first
      orcid = record.author_orcid if record
    end

    author.update(author_orcid: orcid) if orcid
  end

  def fix_missing_orcid
    conflicts = conflicts_list
    grouped_orcids = combined_orcids.group_by { |email, _| email }.transform_values do |entries|
      entries
        .group_by { |_, data| data[:source] }
        .transform_values { |arr| arr.map { |_, data| data[:orcid] }.uniq }
    end

    StashEngine::Author.where(author_orcid: [nil, '']).find_each do |author|
      next if conflicts[author.author_email].present?
      next if grouped_orcids[author.author_email].blank?

      orcid = grouped_orcids[author.author_email][:user]&.first || grouped_orcids[author.author_email][:author]&.first
      next if orcid.blank?

      pp "Updating author #{author.id} - #{author.author_email} with ORCID #{orcid}"
      author.update_column(:author_orcid, orcid) # update_column skips validations/callbacks
    end
  end

  def generate_orcid_conflicts_report
    CSV.open(File.join(REPORTS_DIR, 'orcid_conflicts.csv'), 'w') do |csv|
      csv << ['Email', 'Authors ORCID', 'Users ORCID']
      conflicts_list.each_pair do |email, orcids|
        csv << [
          email,
          orcids[:authors].join("\n"),
          orcids[:users].join("\n")
        ]
      end
    end
  end

  private

  def conflicts_list
    return @conflicts_list if @conflicts_list.present?

    grouped = combined_orcids.group_by { |email, _data| email }
    conflicts = grouped.select do |_email, entries|
      entries.map { |_, data| data[:orcid] }.uniq.size > 1
    end

    @conflicts_list = conflicts.transform_values do |entries|
      {
        authors: entries.select { |_, d| d[:source] == :author }.map { |_, d| d[:orcid] }.uniq,
        users: entries.select { |_, d| d[:source] == :user }.map { |_, d| d[:orcid] }.uniq
      }
    end
  end

  def combined_orcids
    return @combined_orcids if @combined_orcids.present?

    author_map = StashEngine::Author
      .where.not(author_email: [nil, ''])
      .where.not(author_orcid: [nil, ''])
      .pluck(:author_email, :author_orcid)
      .map { |email, orcid| [email, { source: :author, orcid: orcid }] }

    user_map = StashEngine::User
      .where.not(email: [nil, ''])
      .where.not(orcid: [nil, ''])
      .pluck(:email, :orcid)
      .map { |email, orcid| [email, { source: :user, orcid: orcid }] }

    @combined_orcids = author_map + user_map
  end
end
