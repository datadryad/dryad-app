# This is a rake file to  get some identifiers to test the 'manuscript_in_progress' id from the existing dryad api.
require 'httparty'

namespace :old_dryad_api do
  desc 'DEPRECATED -- Get a random manuscript ID/metadata from the Dryad classic API to ease manual testing of autofill'
  task manuscript: :environment do # loads rails environment
    # the ones from http://datadryad.org/pages/journalLookup that don't say they cost $120 is mostly where I got these journals
    pub_issns = %w[2168-0450 1435-0645 1465-7279 1744-957X 1744-7429 1472-4642 1600-0587 2045-7758 2050-084X 2312-0541
                   1399-3003 1558-5646 2056-3744 1752-4571 1365-2435 1466-822X 0018-067X 1537-5315 1365-2656 1365-2664
                   1600-048X 1365-2699 1365-2745 1537-2537 1420-9101 1460-2431 1944-687X 1471-8505 1937-2337 1759-6831
                   1527-974X 2041-210X 1365-294X 1755-0998 1539-1582 1756-1051 1600-0706 1938-5331 1475-4983 2056-2802
                   2575-8314 1537-5293 2054-5703 1435-0661 1076-836X 1548-2324 1537-5323 1938-4254 2049-4408 1938-5129
                   1096-0929 1539-1663]
    pub_issn = pub_issns[rand(pub_issns.length)]

    response = HTTParty.get("#{APP_CONFIG.old_dryad_url}/api/v1/organizations/#{pub_issn}/manuscripts",
                            query: { access_token: APP_CONFIG.old_dryad_access_token },
                            headers: { 'Content-Type' => 'application/json' })
    if response.code > 299 || response.empty?
      puts "Response code: #{response.code}"
      puts "No manuscripts for journal #{pub_issn}"
      exit
    end

    random_record = response[rand(response.length)]
    pp(random_record) # pretty print the record for looking at
    puts ''
    puts "journal: #{random_record['optionalProperties']['Journal']}"
    puts "issn: #{pub_issn}"
    puts "manuscript id: #{random_record['manuscriptId']}"
  end
end
