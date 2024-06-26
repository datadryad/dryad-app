require 'optparse'

module ArgsParser

  def self.parse(attrs = [])
    options = {}
    return options if attrs.blank?

    opts = OptionParser.new
    opts.banner = "Usage: rake add [options]"
    attrs.each do |key|
      opts.on("-o", "--#{key} ARG", String) { |num1| options[key] = num1 }
    end

    args = opts.order!(ARGV) {}
    opts.parse!(args)

    options
  end
end

# require_relative './args_parser'
#
# task :add,  do |t, args|
#   pp ARGV
#   options = ArgsParser.parse([:num1, :num2])
#   pp 'xxxxxxxxx'
#   pp options
#
#   exit
# end
