require 'spec_helper'

module StashEngine
  describe Lock, '.acquire' do

    before :each do
      @reader, @writer = IO.pipe
    end

    def fork_with_new_connection
      config = ActiveRecord::Base.remove_connection
      fork do
        begin
          ActiveRecord::Base.establish_connection(config)
          yield
        ensure
          ActiveRecord::Base.remove_connection
          Process.exit!
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end

    it 'should synchronize processes on the same lock' do
      (1..20).each do |i|
        fork_with_new_connection do
          @reader.close
          ActiveRecord::Base.connection.reconnect!
          Lock.acquire('lock') do
            @writer.puts "Started: #{i}"
            sleep 0.01
            @writer.puts "Finished: #{i}"
          end
          @writer.close
        end
      end
      @writer.close

      # test whether we always get alternating "Started" / "Finished" lines
      lines = []
      @reader.each_line { |line| lines << line }
      expect(lines).to be_truthy # it is empty if the processes all crashed due to a typo or similar
      lines.each_slice(2) do |start, finish|
        start_matchdata = /Started: (.*)/.match(start)
        expect(start_matchdata).to be_truthy
        finish_matchdata = /Finished: (.*)/.match(finish)
        expect(finish_matchdata).to be_truthy
        expect(finish_matchdata[1]).to eq(start_matchdata[1])
      end
      @reader.close
    end
  end
end
