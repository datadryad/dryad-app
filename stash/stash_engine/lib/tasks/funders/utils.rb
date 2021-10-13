require 'csv'
require 'amatch'

module Funders
  class Utils

    attr_reader :lookup

    def initialize
      table = nil
      File.open(File.join(__dir__, 'funderNames.csv'), 'r:UTF-8') do |f|
        table = CSV.parse(f.read, headers: true, liberal_parsing: true)
      end

      # the fields are 'uri' and 'primary_name_display', put into a hash for easy lookup by name as key
      @lookup = {}
      table.each do |row|
        @lookup[row['primary_name_display'].strip.downcase] = { uri: row['uri'], name: row['primary_name_display'].strip }
      end
    end

    # returns the best match like {:uri=>"http://dx.doi.org/10.13039/100017401", :name=>"University of Ruse"} or a nil
    # nil is returned if the Levenshtein distance is > 1/3 of the name length
    def best_match(name:)
      my_match = Amatch::Levenshtein.new(name)
      edit_distances = my_match.match(@lookup.keys)
      min_edit_distance = edit_distances.min

      return nil if min_edit_distance > (name.length / 3.0).ceil

      # otherwise, get the list of items that are of the minimum edit distance
      best_matches = []
      # get the best matches and there may be more than 1
      edit_distances.each.with_index do |distance, idx|
        best_matches.push(@lookup.values[idx]) if distance == min_edit_distance
      end

      # if only one match of this edit distance then return it
      return best_matches.first if best_matches.length == 1

      # otherwise get the pair distance for the tied items
      pair_dist = Amatch::PairDistance.new(name)
      pair_matches = pair_dist.match(best_matches.map { |i| i[:name] })

      best_matches[pair_matches.index(pair_matches.max)]
    end
  end
end
