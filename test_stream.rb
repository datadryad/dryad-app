#!/usr/bin/env ruby
STDOUT.sync = true
require 'byebug'

READ_CHUNK_SIZE = 10.freeze

require 'tempfile'

write_file = Tempfile.create('foo', '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad').binmode
write_file.flock(File::LOCK_NB|File::LOCK_SH)
write_file.sync = true

read_file = File.open(write_file, 'r')

out_file = Tempfile.create('foo', '/Users/sfisher/workspace/direct-to-cdl-dryad/dryad').binmode

write_thread = Thread.new do
  begin
    1.upto(100 + (rand * 100).to_i) do |i|
      # puts "wrote line #{i}, position #{write_file.pos}" if i % 10 == 0
      write_file.write("line #{i}\n")
      sleep(rand/100)
    end
  ensure
    write_file.close
  end
end

read_thread = Thread.new do
  begin
    until read_file.closed?
      # puts "read_file.closed? #{read_file.closed?}, write_file.closed? #{write_file.closed?}"
      while (write_file.closed? && !read_file.closed? )|| ( read_file.pos + READ_CHUNK_SIZE < write_file.pos )
        sleep(rand/30)
        data = read_file.read(10)
        # puts "#{data}, position #{read_file.pos}"
        $stdout.write data
        out_file.write data
        if read_file.eof?
          read_file.close
          break
        end
      end
      sleep 2
    end
  ensure
    read_file.close unless read_file.closed?
    write_file.close unless write_file.closed?
    out_file.close unless out_file.closed?
  end
end

write_thread.join
read_thread.join

puts "files match = #{File.read(read_file.path) == File.read(out_file.path)}"

File.unlink(write_file.path) if File.exist?(write_file.path)
File.unlink(out_file.path) if File.exist?(out_file.path)

puts 'done'
