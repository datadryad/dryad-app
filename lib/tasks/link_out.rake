require 'httparty'

namespace :link_out do

  LINK_OUT_DIR = "#{Rails.root}/tmp/link_out/".freeze

  desc 'Generate and then Push the LinkOut file(s) to the LinkOut FTP server'
  task publish: :environment do
    Rake::Task["link_out:create"].execute
    Rake::Task["link_out:push"].execute
  end

  desc 'Generate the LinkOut file(s)'
  task create: :environment do
    make_dir
    Rake::Task["link_out:create_labs_link_profile"].execute
    Rake::Task["link_out:create_pubmed_link_out"].execute
    Rake::Task["link_out:create_labs_link_link_out"].execute
  end

  desc 'Generate the PubMed Link Out file ?(pubmedlinkout.xml'
  task create_pubmed_link_out: :environment do
    xml_name = 'pubmedlinkout.xml'
    link_out_schema = 'http://www.ncbi.nlm.nih.gov/entrez/linkout/doc/LinkOut.dtd'

    p "Generating LinkSet file at #{LINK_OUT_DIR}#{xml_name} at #{Time.now.strftime('%H:%m:%s')}"
    identifiers = StashEngine::Identifier.cited_by_pubmed.map do |identifier|
      { doi: identifier.to_s, pubmed_id: identifier.internal_data.where(data_type: 'pubmedID').first.value }
    end

    doc = Nokogiri::XML(ActionView::Base.new('app/views').render(
      file: 'link_out/pubmed_link_out.xml.erb',
      locals: {
        provider_id: '7893',
        database: 'PubMed',
        link_base: 'dryad.pubmed.',
        icon_url: "#{Rails.application.routes.url_helpers.root_url}images/DryadLogo-Button.png",
        callback_base: "#{Rails.application.routes.url_helpers.root_url}discover?",
        callback_rule: 'query=%22&lo.doi;%22',
        subject_type: 'supplemental materials',
        identifiers: identifiers
      }
    ), nil, 'UTF-8')

    # Skipping the Schema validation for now because their DTD file is causing Nokogiri to throw a
    #    `Nokogiri::XML::SyntaxError: ERROR: The document 'in_memory_buffer' has no document element.`
    #
    # xsd = Nokogiri::XML::Schema(link_out_schema)
    # p "Valid XML? #{xsd.valid?(doc)}"
    # p "The XML document does not conform to the Schema defined at: #{link_out_schema}:" unless xsd.valid?(doc)
    # xsd.validate(doc).each { |err| err.to_s } unless xsd.valid?(doc)

    doc.create_internal_subset('html', '-//NLM//DTD LinkOut 1.0//EN', link_out_schema)
    file = File.write("#{LINK_OUT_DIR}#{xml_name}", doc.to_xml)
    p "Finished generating #{xml_name} with #{identifiers.length} links at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the LabLinks Profile file (labslinkprofile.xml)'
  task create_labs_link_profile: :environment do
    xml_name = 'labslinkprofile.xml'

    p "Generating LabsLink Profile file at #{LINK_OUT_DIR}#{xml_name} at #{Time.now.strftime('%H:%m:%s')}"
    doc = Nokogiri::XML(ActionView::Base.new('app/views').render(
      file: 'link_out/labs_link_profile.xml.erb',
      locals: {
        id: '1012',
        name: 'Dryad Digital Repository',
        description: 'Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.',
        email: 'linkout@datadryad.org'
      }
    ), nil, 'UTF-8')

    file = File.write("#{LINK_OUT_DIR}#{xml_name}", doc.to_xml)
    p "Finished generating #{xml_name} at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the LabsLink LinkOut file (labslinklinkout.xml)'
  task create_labs_link_link_out: :environment do
    xml_name = 'labslinklinkout.xml'

    p "Generating LinkSet file at #{LINK_OUT_DIR}#{xml_name} at #{Time.now.strftime('%H:%m:%s')}"
    identifiers = StashEngine::Identifier.cited_by_pubmed

    doc = Nokogiri::XML(ActionView::Base.new('app/views').render(
      file: 'link_out/labs_link_link_out.xml.erb',
      locals: {
        provider_id: '1012',
        database: 'MED',
        show_url_base: "#{Rails.application.routes.url_helpers.root_url}stash/dataset/",
        identifiers: identifiers
      }
    ), nil, 'UTF-8')

    file = File.write("#{LINK_OUT_DIR}#{xml_name}", doc.to_xml)
    p "Finished generating #{xml_name} at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Delete the LinkOut file(s)'
  task delete: :environment do
    make_dir
    files = Dir.entries("#{LINK_OUT_DIR}/*.xml")
    p "Deleting #{files.length} LinkOut files from #{LINK_OUT_DIR}"
    files.each { |f| File.delete(f) }
  end

  desc 'Push the LinkOut file(s) to the LinkOut FTP server'
  task push: :environment do
    p "Submitting XML files in #{LINK_OUT_DIR} to the LinkOut FTP server"
    p "  TODO: Update the code to push to the FTP server!"
  end

  private

  def make_dir
    return if Dir.exist?(LINK_OUT_DIR)
    Dir.mkdir(LINK_OUT_DIR)
    p "Created LinkOut dir: #{LINK_OUT_DIR}"
  end

end