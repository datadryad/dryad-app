require 'rake'
require 'optparse'

namespace :configs do

  ARGV.shift
  ARGV.shift

  desc "Symlink the config files from external directory rake configs:symlink"
  task symlink: :environment do |args|

    options = {}
    OptionParser.new(args) do |opts|
      opts.banner = "Usage: rake configs:symlink [options]"
      opts.on('-d', '--directory {directory}', 'Directory') do |directory|
        options[:dir] = directory
      end
    end.parse!

    if options[:dir].blank?
      puts "Usage: rake configs:symlink -- -d [dash2-config directory]"
      exit 0
    end

    if !File.exist?(options[:dir]) || !File.directory?(options[:dir])
      puts 'The directory you entered does not exist'
      exit 0
    end

    files = Dir.glob(File.join(options[:dir], "**", "*.yml"))
    files.each do |f|
      local_file = File.join('.', f[options[:dir].length..-1])
      if !File.exist?(local_file) || File.symlink?(local_file)
        File.delete(local_file) if File.symlink?(local_file)
        File.symlink(File.expand_path(f), local_file)
        puts "Symbolic linking #{local_file} to #{f}"
      else
        puts "Cannot symlink #{f} since a local file already exists with this name"
      end
    end

    exit 0
  end

end
