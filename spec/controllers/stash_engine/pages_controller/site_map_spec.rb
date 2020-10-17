# require 'stash_engine/pages/site_map'
require 'byebug'
require 'nokogiri'

# RSpec.configure(&:infer_spec_type_from_file_location!)

module StashEngine
  class PagesController
    RSpec.describe SiteMap, type: :model do

      before(:each) do
        @identifiers = []
        1.upto(14).each do |_n|
          id = create(:identifier, pub_state: 'published')
          create(:resource, identifier_id: id.id, meta_view: true)
          @identifiers << id
        end
        @site_map = StashEngine::PagesController::SiteMap.new
      end

      describe '#count' do
        it 'returns the correct count of public datasets' do
          expect(@site_map.count).to eq(14)
        end

        it 'returns the correct count if some are not published' do
          @identifiers[0].update(pub_state: 'withdrawn')
          @identifiers[1].update(pub_state: 'unpublished')
          @identifiers[2].resources.first.update(meta_view: false)
          expect(@site_map.count).to eq(11)
        end
      end

      describe '#pages' do
        it 'has three pages for 14 records with page size of 5' do
          @site_map.page_size = 5
          expect(@site_map.pages).to eq(3)
        end
      end

      describe '#sitemap_index' do
        it 'creates an index into all pages' do
          @site_map.page_size = 5
          xml_str = @site_map.sitemap_index
          doc = Nokogiri::XML(xml_str)
          doc.remove_namespaces!
          sitemapindex = doc.at_xpath('//sitemapindex')
          expect(sitemapindex.to_s).to include('</sitemapindex>') # it has the element and closes it
          sitemaps = sitemapindex.xpath('//sitemap')
          expect(sitemaps[0].to_s).to include('sitemap.xml?page=1')
          expect(sitemaps[1].to_s).to include('sitemap.xml?page=2')
          expect(sitemaps[2].to_s).to include('sitemap.xml?page=3')
        end
      end

      describe '#sitemap_page' do
        it 'has correct dois in url for each dataset' do
          @site_map.page_size = 5
          xml_str = @site_map.sitemap_page(2)
          doc = Nokogiri::XML(xml_str)
          doc.remove_namespaces!
          urls = doc.xpath('//urlset/url')
          expect(urls.length).to eq(5)
          5.upto(9) do |i|
            expect(urls[i - 5].to_s).to include(@identifiers[i].identifier)
          end
        end

        it 'has correct timestamps in page for each url' do
          @site_map.page_size = 5
          xml_str = @site_map.sitemap_page(2)
          doc = Nokogiri::XML(xml_str)
          doc.remove_namespaces!
          urls = doc.xpath('//urlset/url')
          expect(urls.length).to eq(5)
          5.upto(9) do |i|
            expect(urls[i - 5].to_s).to include(@identifiers[i].updated_at.utc.iso8601)
          end
        end
      end
    end
  end
end
