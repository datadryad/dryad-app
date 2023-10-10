# :nocov:
namespace :mysql do
  desc 'update utf8 to utf8mb4 for existing tables'
  task update_utf8mb4: :environment do
    $stdout.sync = true # keeps stdout from buffering and writes right away
    puts "Are you sure you want to update all tables to utf8mb4 for #{Rails.env}?  (Type 'yes' to proceed.)"
    response = $stdin.gets
    exit 1 unless response.strip.casecmp('YES').zero?

    tables = ActiveRecord::Base.connection.tables
    tables.each do |table|
      puts "#{Time.new} Updating #{table}" # it's nice to see times to know how slow it is ;-)

      query = "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
      ActiveRecord::Base.connection.execute(query)
    end

    # NOTE: to alter the default for a database, do this, but it doesn't alter the varchar/text columns which the
    # above does.
    #
    # ALTER DATABASE
    #     database_name
    #     CHARACTER SET = utf8mb4
    #     COLLATE = utf8mb4_unicode_ci;
  end
end
# :nocov:
