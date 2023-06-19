module Tasks
  module Keywords
    class Plos

      SCHEME = 'PLOS Subject Area Thesaurus'.freeze
      SCHEME_URI = 'https://github.com/PLOS/plos-thesaurus'.freeze

      def initialize(fn:)
        @fn = fn
        @keywords = read_keywords
      end

      def populate
        @keywords.each_with_index do |k, idx|
          subjs = StashDatacite::Subject.where(subject: k)
          if subjs.count.zero?
            # add one that doesn't exist
            StashDatacite::Subject.create(subject: k, subject_scheme: SCHEME, scheme_URI: SCHEME_URI)
          else
            subjs.each do |subj|
              next if subj.subject_scheme == 'fos' || (subj.subject == k && subj.subject_scheme == SCHEME && subj.scheme_URI == SCHEME_URI)

              # update the existing one to the correct values, so it reflects the vocabulary it came from
              subj.update(subject: k, subject_scheme: SCHEME, scheme_URI: SCHEME_URI)
            end
          end
          puts "Processed #{idx + 1} of #{@keywords.length} keywords" if (idx + 1) % 100 == 0
        end
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
end
