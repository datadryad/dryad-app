# require 'stash_engine/pages/site_map'
require 'byebug'
require 'nokogiri'

module StashEngine
  class PagesController
    RSpec.describe SiteMap, type: :model do

      let(:subject) { StashEngine::PagesController::SiteMap.new }

      before do
        Rails.cache.clear
        solr = RSolr.connect(url: APP_CONFIG.solr_url)
        solr.delete_by_query('*:*')
        solr.commit
        1.upto(8).each do |n|
          r = create(:resource_published, updated_at: n.seconds.ago)
          r.reload.submit_to_solr
        end
        sleep 0.1
        @identifiers = StashEngine::Resource.with_public_metadata.order(updated_at: :asc).map(&:identifier)
      end

      describe '#count' do
        it 'returns the correct count of public datasets' do
          expect(subject.count).to eq(8)
        end
      end

      context 'xml pages' do
        before { subject.per_page = 3 }

        describe '#pages' do
          it 'has three pages for 8 records with page size of 3' do
            expect(subject.pages).to eq(3)
          end
        end

        describe '#sitemap_index' do
          it 'creates an index into all pages' do
            xml_str = subject.sitemap_index
            doc = Nokogiri::XML(xml_str)
            doc.remove_namespaces!
            sitemapindex = doc.at_xpath('//sitemapindex')
            expect(sitemapindex.to_s).to include('</sitemapindex>') # it has the element and closes it
            sitemaps = sitemapindex.xpath('//sitemap')
            expect(sitemaps.length).to eq(4)
            expect(sitemaps[0].to_s).to include('sitemap.xml?page=0')
            expect(sitemaps[1].to_s).to include('sitemap.xml?page=1')
            expect(sitemaps[2].to_s).to include('sitemap.xml?page=2')
            expect(sitemaps[3].to_s).to include('sitemap.xml?page=3')
          end
        end

        describe '#sitemap_page' do
          it 'has correct dois in url for each dataset' do
            xml_str = subject.sitemap_page(2)
            doc = Nokogiri::XML(xml_str)
            doc.remove_namespaces!
            urls = doc.xpath('//urlset/url//loc')
            expect(urls.length).to eq(3)
            dois = @identifiers[3..5].map(&:identifier)
            urls.map(&:text).each_with_index do |url, i|
              expect(url).to include(dois[i])
            end
          end

          it 'has correct timestamps in page for each url' do
            xml_str = subject.sitemap_page(3)
            doc = Nokogiri::XML(xml_str)
            doc.remove_namespaces!
            mods = doc.xpath('//urlset/url//lastmod')
            expect(mods.length).to eq(2)
            dates = @identifiers[6..8].map { |id| id.latest_resource.updated_at.iso8601 }
            mods.map(&:text).each_with_index do |mod, i|
              expect(mod).to include(dates[i])
            end
          end
        end
      end
    end
  end
end
