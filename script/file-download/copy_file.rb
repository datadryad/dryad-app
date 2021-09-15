require 'http'
require 'ruby-progressbar'

class CopyFile

  def initialize(save_path:)
    @save_path = save_path
  end

  def save(url:, token:, filename:)
    puts url

    # get redirect to the S3 presigned url
    redir = HTTP.get(url, headers: { 'Authorization' => "Bearer #{token}" })
    if redir.code > 399
      STDERR.puts "Error #{redir.code} getting S3 presigned url for #{url}"
      return
    end

    response = HTTP.get(redir.headers['Location'])

    outfn = File.join(@save_path, filename)
    puts "writing #{outfn}"
    File.open(outfn, 'wb') do |outfile|
      completed_size = 0
      total_size = response['Content-Length'].to_i
      progressbar = ProgressBar.create

      chunk_count = 0
      response.body.each do |chunk|
        chunk_count += 1
        completed_size += chunk.bytesize
        percent_complete = completed_size/total_size.to_f * 100
        progressbar.progress = percent_complete if chunk_count % 100 == 0 # only update every 100 chunks
        outfile.write(chunk)
      end
      progressbar.progress = 100
    end
  end
end