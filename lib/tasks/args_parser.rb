require 'optparse'
# rubocop:disable Lint/EmptyBlock
module Tasks
  module ArgsParser

    def self.parse(*attributes)
      options = OpenStruct.new
      return options if attributes.blank?

      opts = OptionParser.new
      opts.banner = 'Usage: rake add [options]'
      attributes.each do |key|
        opts.on('-o', "--#{key}=value", String) { |value| options[key] = value }
      end

      do_not_parse = '--force-color --format RSpec::Github::Formatter --format progress --tag ~skip'
      args = ARGV - do_not_parse.split
      args = opts.order!(args) {}
      opts.parse!(args)

      options
    end
  end
end
# rubocop:enable Lint/EmptyBlock
