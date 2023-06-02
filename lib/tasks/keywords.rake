namespace :keywords do
  task update_plos: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f

    if ENV['PLOS_PATH'].blank? || ENV['RAILS_ENV'].blank?
      puts 'Please enter the path to the PLoS keywords as the PLOS_PATH environment variable'
      puts 'For example: PLOS_PATH="/my/path/to/plosthes.2020-1.full.tsv"'
      puts ''
      puts 'You can get the Excel files from https://github.com/PLOS/plos-thesaurus.'
      puts 'then open in a program that can convert to tab separated values such as Google docs.'
      puts '(Choose File > Download > Tab-separated values in Google docs)'
      puts 'Excel seems to export as a mystery character set that causes UTF-8 problems, so'
      puts 'probably best to avoid Excel for this.'
      puts ''
      puts 'Also be sure to set the RAILS_ENV environment variable for the correct environment'
      puts ''
      puts 'PLOS also has a file named plosthes.xxxx.synonyms.xlsx which are non-preferred terms'
      puts 'and is not currently used for import, but we might reconsider that in the future if'
      puts 'we would like a more expansive list of synonym keywords.'
      exit
    end

    # without silencing this, all I saw was ActiveRecord SQL logging and it was hard to see the progress
    Rails.logger.silence do
      plos = Tasks::Keywords::Plos.new(fn: ENV['PLOS_PATH'])
      plos.populate
    end

    puts 'Done populating PLoS keywords'
  end
end
