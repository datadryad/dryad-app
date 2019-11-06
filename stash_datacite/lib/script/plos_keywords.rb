# this can be run from rails console for one-off runs that are probably infrequent
# do require 'script/plos_keywords', then you can use Script::PlosKeywords.new(filename_of_tsv)
# where the tab separated value file is an export of PLoS' excel spreadsheet into tab separated.
# And then run instance.populate to stick the stuff into your subjects table for DataCite.

# PS, I had to run the tsv output from excel through sublime text and set the encoding to utf-8 and save to fix excel problems.

module Script
  class PlosKeywords
    SCHEME = 'PLOS Subject Area Thesaurus'.freeze
    SCHEME_URI = 'https://github.com/PLOS/plos-thesaurus'.freeze

    def initialize(filename_of_tsv = '/Users/scottfisher/Desktop/plosthes.2016-3.full.txt') # should be full path
      @fn = filename_of_tsv
    end

    def populate
      keywords = read_keywords
      count = 0
      keywords.each do |k|
        next if StashDatacite::Subject.where(subject: k).exists?
        count += 1
        StashDatacite::Subject.create(subject: k, subject_scheme: SCHEME, scheme_URI: SCHEME_URI)
      end
      puts "Added #{count} of #{keywords.length} keywords (#{keywords.length - count} existing)"
    end

    private

    def read_keywords
      keywords = []
      File.open(@fn, 'r') do |f|
        all = f.read.strip
        lines = all.split("\r")
        lines.each do |line|
          my_line = line.strip
          keywords.push(my_line) unless my_line.start_with?("Item1\t")
        end
      end
      keywords.uniq
    end
  end
end
