# a helper to do webmock range requests without being so verbose and annoying in tests
module HttpRangeHelper
  def stub_range_request(url:, r_start:, r_end:, body:, file_size:)
    stub_request(:get, url).
      with(headers: { 'Range' => "bytes=#{r_start}-#{r_end}" }).
      to_return(status: 206, body: body, headers: { 'Content-Range' => "bytes #{r_start}-#{r_end}/#{file_size}" })
  end
end