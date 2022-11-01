require 'time'
require 'ipaddr'
require 'uri'

# this is a long, but very consistent and simple class, so suck it rubocop
module Counter
  class ValidateFile

    def initialize(filename:)
      @filename = filename
      full_path = File.expand_path(filename)
      @out_file = File.join(File.dirname(full_path), "#{File.basename(full_path)}-fixed")
    end

    VALIDATION_METHODS = %w[event_time ip_address session_cookie user_cookie user_id request_url
                            doi filename size user_agent title publisher publisher_id authors publication_date version
                            alternate_id target_url year_of_publication].freeze

    # used for display of bad items
    LONGEST_METHOD = VALIDATION_METHODS.map(&:length).max.freeze

    def validate_file
      File.open(@out_file, 'w:UTF-8') do |f|
        File.open(@filename).each_with_index do |line, index|
          @badline = false # badline is set to true if it doesn't validate
          @line_no = index
          my_line = line.strip
          next if my_line.start_with?('#') || my_line == ''

          validate_line(line: my_line)
          if @badline == false
            f.write("#{@pieces.join("\t")}\n")
          else
            output_badinfo
          end
        end
      end
    end

    def validate_line(line:)
      @pieces = line.split("\t")
      # the following is a bad hack to fix missing grid ids everywhere
      @pieces.insert(12, 'grid.466587.e') if @pieces.length == 18
      if @pieces.length != VALIDATION_METHODS.length
        return error(msg: "Incorrect number of fields: should be #{VALIDATION_METHODS.length} fields, #{@pieces.length} found")
      end

      VALIDATION_METHODS.each_with_index do |meth, index|
        send("validate_#{meth}", @pieces[index])
      end
    end

    # must be present and be iso8601 string
    def validate_event_time(item)
      error(msg: 'Invalid iso8601 string', item: __method__.to_s) unless valid_iso_8601(item)
    end

    # must have an IP address of some kind
    def validate_ip_address(item)
      error(msg: 'Invalid IP address string', item: __method__.to_s) if (begin
        IPAddr.new(item)
      rescue StandardError
        nil
      end).nil?
    end

    # don't know what these exactly look like, make stricter later if needed
    def validate_session_cookie(_item)
      nil
    end

    # don't know what these exactly look like, make stricter later if needed
    def validate_user_cookie(_item)
      nil
    end

    # don't know what these exactly look like, make stricter later if needed
    def validate_user_id(_item)
      nil
    end

    def validate_request_url(item)
      error(msg: 'Invalid URL', item: __method__.to_s) unless item =~ URI::DEFAULT_PARSER.make_regexp
    end

    # see https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    def validate_doi(item)
      error(msg: 'Invalid DOI', item: __method__.to_s) unless item =~ %r{^doi:10.\d{4,9}/[-._;()/:A-Z0-9]+$}i
    end

    # make stricter later if needed
    def validate_filename(_item)
      nil
    end

    # nothing or - or a numeric
    def validate_size(item)
      error(msg: 'Invalid size', item: __method__.to_s) unless item =~ /^$|^-$|^\d+$/
    end

    # just a string, so ignore
    def validate_user_agent(_item)
      nil
    end

    # just a string, but shouldn't be blank
    def validate_title(item)
      error(msg: 'Title may not be blank', item: __method__.to_s) if blank?(item)
    end

    # just a string, but shouldn't be blank
    def validate_publisher(item)
      error(msg: 'Publisher may not be blank', item: __method__.to_s) if blank?(item)
    end

    def validate_publisher_id(item)
      error(msg: 'Publisher ID may not be blank', item: __method__.to_s) if blank?(item)
      error(msg: 'Publisher ID must match a certain format', item: __method__.to_s) unless item =~ %r{^grid.|^isni:|^https://ror.org/}
    end

    def validate_authors(item)
      error(msg: 'Authors may not be blank', item: __method__.to_s) if blank?(item)
    end

    # a bazillion formats, just checking it's not blank here
    def validate_publication_date(item)
      error(msg: 'Publication date may not be blank', item: __method__.to_s) if blank?(item)
    end

    # I'm not really sure this needs to be set, does it?
    def validate_version(_item)
      nil
    end

    # doesn't need to be set
    def validate_alternate_id(_item)
      nil
    end

    # I believe there should be a target URL, even if it's just a metadata page about itself?
    def validate_target_url(item)
      error(msg: 'Invalid URL', item: __method__.to_s) unless item =~ URI::DEFAULT_PARSER.make_regexp
    end

    def validate_year_of_publication(item)
      error(msg: 'Invalid year of publication', item: __method__.to_s) unless item =~ /^\d+$/i
    end

    private

    # private helper methods for this class below here

    def error(msg:, item: nil)
      @badline = true
      if item.nil?
        puts "#{@filename}:#{@line_no + 1} #{msg}"
      else
        puts "#{@filename}:#{@line_no + 1}:#{item} #{msg}"
      end
    end

    def valid_iso_8601(t)
      Time.iso8601(t)
      true
    rescue ArgumentError
      false
    end

    def blank?(i)
      ['-', ''].include?(i)
    end

    def output_badinfo
      VALIDATION_METHODS.each_with_index do |v, i|
        puts "#{v.rjust(LONGEST_METHOD)}: #{i >= @pieces.length ? 'MISSING FIELD' : @pieces[i]}"
      end
      puts ''
    end
  end
end
