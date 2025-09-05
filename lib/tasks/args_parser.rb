require 'optparse'
# rubocop:disable Lint/EmptyBlock
module Tasks
  module ArgsParser

    def self.parse(*attributes)
      options = OpenStruct.new
      return options if attributes.blank?

      args = ARGV.drop_while { |a| a != "--" }[1..] || []
      args.each_slice(2) do |key, value|
        next unless key&.start_with?("--")

        my_key = key.sub(/^--/, '').to_sym
        next unless my_key.in?(attributes)

        options[my_key] = value
      end

      options
    end
  end
end
# rubocop:enable Lint/EmptyBlock
