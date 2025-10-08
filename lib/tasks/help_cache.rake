task help_cache: :environment do
  HELP_PAGES.each do |page|
    Net::HTTP.get_response(URI.parse("#{ROOT_URL}#{page[:path]}"))
  end
end
