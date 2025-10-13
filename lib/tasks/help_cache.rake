task help_cache: :environment do
  HELP_PAGES.each do |page|
    Net::HTTP.get_response(URI.parse("http://localhost:3000#{page[:path]}"))
  end
end
