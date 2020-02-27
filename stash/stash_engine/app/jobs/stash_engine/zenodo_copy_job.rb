module StashEngine
  class ZenodoCopyJob < ActiveJob::Base
    queue_as :zenodo_copy

    TEST_FILE = Rails.root.join('log', 'test_active_job.txt')

    before_enqueue do |job|
      File.open(TEST_FILE, 'a') { |f| f.puts "before_enqueue:\n#{job.inspect}\n" }
    end

    after_enqueue do |job|
      File.open(TEST_FILE, 'a') { |f| f.puts "after_enqueue:\n#{job.inspect}\n" }
    end

    before_perform do |job|
      File.open(TEST_FILE, 'a') { |f| f.puts "before_perform:\n#{job.inspect}\n" }
    end

    after_perform do |job|
      File.open(TEST_FILE, 'a') { |f| f.puts "after_perform:\n#{job.inspect}\n" }
    end

    def perform(*args)
      # Do something later
      sleep rand(10)
      File.open(TEST_FILE, 'a') { |f| f.puts "\n\nRUNNING MY JOB #{args[0]}\n\n" }
    end
  end
end
