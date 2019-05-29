Dir.glob('../link_out/*.rb') { |f| require_relative f }

# rubocop:disable Metrics/BlockLength
namespace :link_out do

  desc 'Generate and then push the LinkOut file(s) to the LinkOut FTP servers'
  task publish: :environment do
    Rake::Task['link_out:create'].execute
    Rake::Task['link_out:push'].execute
  end

  desc 'Generate the LinkOut file(s)'
  task create: :environment do
    make_dir
    Rake::Task['link_out:create_pubmed_linkouts'].execute
    Rake::Task['link_out:create_labslink_linkouts'].execute
    Rake::Task['link_out:create_genbank_linkouts'].execute
  end

  desc 'Generate the PubMed Link Out files'
  task create_pubmed_linkouts: :environment do
    p "Generating LinkOut files for Pubmed #{Time.now.strftime('%H:%m:%s')}"
    pubmed_service = LinkOut::PubmedService.new
    pubmed_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the LabsLink LinkOut files'
  task create_labslink_linkouts: :environment do
    p "Generating LinkOut files for LabLinks #{Time.now.strftime('%H:%m:%s')}"
    euro_pubmed_service = LinkOut::EuroPubmedService.new
    euro_pubmed_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the GenBank LinkOut files'
  task create_genbank_linkouts: :environment do
    p "Generating LinkOut files for GenBank #{Time.now.strftime('%H:%m:%s')}"
    euro_pubmed_service = LinkOut::EuroPubmedService.new
    euro_pubmed_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Push the LinkOut files to the LinkOut FTP servers'
  task push: :environment do
    p "Publishing LinkOut files"
    p "  processing Pubmed files:"
    put_to_ftp(compress(EURO_PUBMED_CENTRAL_HASH[:profile_file]), APP_CONFIG.link_out.pubmed_central)
    put_to_ftp(compress(EURO_PUBMED_CENTRAL_HASH[:linkout_file]), APP_CONFIG.link_out.pubmed_central) if valid_xml?(EURO_PUBMED_CENTRAL_HASH[:linkout_file], EURO_PUBMED_CENTRAL_HASH[:schema])
    p "  processing LabsLink files"
    put_to_ftp(compress(NCBI_HASH[:profile_file]), NCBI_HASH.link_out.ncbi) if valid_xml?(NCBI_HASH[:linkout_file], NCBI_HASH[:schema])
    put_to_ftp(compress(NCBI_HASH[:linkout_file]), NCBI_HASH.link_out.ncbi) if valid_xml?(NCBI_HASH[:linkout_file], NCBI_HASH[:schema])
    p "  processing GenBank files"
    put_to_ftp(compress(NCBI_HASH[:profile_file]), NCBI_HASH.link_out.ncbi) if valid_xml?(NCBI_HASH[:linkout_file], NCBI_HASH[:schema])
    put_to_ftp(compress(NCBI_HASH[:linkout_file]), NCBI_HASH.link_out.ncbi) if valid_xml?(NCBI_HASH[:linkout_file], NCBI_HASH[:schema])
  end

end
# rubocop:enable Metrics/BlockLength
