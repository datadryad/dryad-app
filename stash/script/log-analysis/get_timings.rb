#!/usr/bin/env ruby
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'byebug'
end

fn = ARGV[0]

lines = File.readlines(fn).grep(/Completed.+in.+\d+ms/)

total_ms = 0

def time_as_str(ms)
  sec = ms / 1000
  my_ms = ms % 1000
  (Time.utc(2000, 'jan', 1, 0, 0, 0) + sec).strftime('%H:%M:%S') + ".#{my_ms.to_s.rjust(3, '0')}"
end

ms_array = [0, 50, 100, 150, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000,
            7000, 8000, 9000, 10_000, 15_000, 20_000, 25_000, 30_000, 35_000, 40_000, 45_000, 50_000, 55_000, 60_000,
            75_000, 90_000, 105_000, 120_000, 180_000, 240_000, 300_000, 600_000, 900_000, 1_200_000, 1_800_000, 360_000, 1_440_000]

# create array of ranges
ms_ranges = []
ms_array.each_with_index do |val, idx|
  next if idx == 0

  ms_ranges.push((ms_array[idx - 1]..val))
end

range_buckets = Array.new(ms_ranges.size, 0)

lines.each do |line|
  my_ms = line.match(/in (\d+)ms/)[1].to_i
  total_ms += my_ms
  ms_ranges.each_with_index do |range, idx|
    if range.cover?(my_ms)
      range_buckets[idx] += 1
      break
    end
  end
end

puts "#{total_ms} total ms"
puts "#{total_ms.to_f / lines.count} average ms"

puts ''

ms_ranges.each_with_index do |range, idx|
  puts "#{time_as_str(range.begin)} to #{time_as_str(range.end)}: #{range_buckets[idx]}"
end
