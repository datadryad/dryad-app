require 'digest'
require 'logger'
require 'open-uri'

module Stash
  class Checksums
    BUFSIZE = 32_000

    class CheckDigest < Checksums
      attr_accessor :type, :algorithm, :checksum, :checksum_type, :input_size

      def initialize(checksum_type)
        super([])
        @type = get_algorithm(checksum_type)
        raise "Digest type not found: #{checksum_type}" if @type.nil?

        @algorithm = @type.new
        @algorithm.reset
      rescue StandardError => e
        raise "Error initializing CheckDigest: #{e.message}"
      end

      def dump(header)
        "#{header}\n " \
          "- checksum_type: #{@checksum_type}\n " \
          "- checksum: #{@type}\n " \
          "- input_size: #{@input_size}\n"
      end
    end

    attr_accessor :digest_list, :input_size

    def initialize(types)
      @digest_list = []
      @input_size = 0
      types.each do |checksum_type|
        digest = CheckDigest.new(checksum_type)
        @digest_list << digest
      end
    rescue StandardError => e
      raise "Error initializing Checksums: #{e.message}"
    end

    def self.get_checksums(types, input)
      checksums = Checksums.new(types)
      checksums.process(input)
      checksums
    rescue StandardError => e
      raise "Error getting checksums: #{e.message}"
    end

    def process(input)
      if URI.parse(input).is_a?(URI::HTTP)
        process_url(input)
      elsif input.is_a?(File)
        process_file(input)
      elsif input.is_a?(IO)
        process_stream(input)
      else
        raise 'Unsupported input type'
      end
    rescue StandardError => e
      raise "Error processing input: #{e.message}"
    end

    def get_checksum(checksum_type)
      mdt = get_algorithm(checksum_type)
      raise "Digest type not found: #{checksum_type}" if mdt.nil?

      digest = @digest_list.find { |d| d.type == mdt }
      digest&.checksum
    end

    def get_algorithm(algorithm_s)
      return nil if algorithm_s.nil? || algorithm_s.empty?

      algorithm_s = algorithm_s.downcase.tr('-', '')
      Digest.const_get(algorithm_s.upcase.to_sym)
    rescue StandardError
      nil
    end

    private

    def process_url(url)
      URI.parse(url).open do |f|
        process_stream(f)
      end
    end

    def process_file(file)
      File.open(file, 'rb') do |f|
        process_stream(f)
      end
    end

    def process_stream(input_stream)
      input_stream.each(nil, BUFSIZE) do |chunk|
        @input_size += chunk.length
        @digest_list.each { |digest| digest.algorithm.update(chunk) }
      end

      @digest_list.each do |digest|
        finish_digest(digest)
        digest.input_size = @input_size
      end
    end

    def finish_digest(digest)
      digest.checksum = digest.algorithm.hexdigest
    end
  end
end

# Example usage
begin
  types = %w[md5 sha256]

  DATA = '/apps/replic/test/sword/big/big.zip'.freeze
  test_file = DATA

  start_time = Time.now
  checksums = Stash::Checksums.get_checksums(types, test_file)
  end_time = Time.now

  puts "Process(#{Stash::Checksums::BUFSIZE})=#{end_time - start_time}"
  puts "get_input_size=#{checksums.input_size}"

  types.each do |type|
    checksum = checksums.get_checksum(type)
    puts "get_checksum(#{type}): #{checksum}"
  end
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
end
