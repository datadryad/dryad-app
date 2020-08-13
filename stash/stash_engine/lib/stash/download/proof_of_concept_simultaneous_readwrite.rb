#!/usr/bin/env ruby
#
# NOTE: This code isn't used in the actual product, but it is proof of concept for using threads to both write to
# a file and read from the file at the same time with threading.  It was to test my assumptions about the logic
# and the possibly complex concurrency issues between threads interacting with the same file at the same time.
#
# It creates output manually rather than from an external file and has some sleep statements that may be changed
# to be sure it doesn't do things such as reading past the end of the file (or cut it off) if the reading stream reads faster than
# the writing stream can supply data.
#
# Also allowed me to mess with the file settings so I could find the right ones that would allow concurrent access.

STDOUT.sync = true
require 'byebug'

READ_CHUNK_SIZE = 10

require 'tempfile'

write_file = Tempfile.create('foo', '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad').binmode
write_file.flock(File::LOCK_NB | File::LOCK_SH)
write_file.sync = true

read_file = File.open(write_file, 'r')

out_file = Tempfile.create('foo', '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad').binmode

write_thread = Thread.new do

  1.upto(100 + (rand * 100).to_i) do |i|
    # puts "wrote line #{i}, position #{write_file.pos}" if i % 10 == 0
    write_file.write("line #{i}\n")
    sleep(rand / 100) # simulate delays in writing data
  end
ensure
  write_file.close

end

read_thread = Thread.new do

  until read_file.closed?
    # puts "read_file.closed? #{read_file.closed?}, write_file.closed? #{write_file.closed?}"
    while (write_file.closed? && !read_file.closed?) || (read_file.pos + READ_CHUNK_SIZE < write_file.pos)
      sleep(rand / 30) # simulate delays in reading data
      data = read_file.read(10)
      # puts "#{data}, position #{read_file.pos}"
      $stdout.write data
      out_file.write data
      if read_file.eof?
        read_file.close
        break
      end
    end
    sleep 2 # a sleep to wait for more data to be consumed
  end
ensure
  read_file.close unless read_file.closed?
  write_file.close unless write_file.closed?
  out_file.close unless out_file.closed?

end

write_thread.join
read_thread.join

puts "files match = #{File.read(read_file.path) == File.read(out_file.path)}"

File.unlink(write_file.path) if File.exist?(write_file.path)
File.unlink(out_file.path) if File.exist?(out_file.path)

puts 'done'
