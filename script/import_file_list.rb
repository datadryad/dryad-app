# a manual class for importing a file list from an atom feed from Merritt.
# Useful so that we can use the ActiveRecord connection for whatever environment to populate it from the atom feed.

class ImportFileList

  def initialize(atom_url: 'https://merritt.cdlib.org/object/recent.atom?collection=ark:/13030/m5q82t8x',
                 ark: 'ark:/b6078/d1ks3m',
                 resource_id: 272)
    @atom_url = atom_url
    @ark = ark
    @resource_id = resource_id
  end

  def populate_files
    noko = get_atom
    items = filter(noko)
    items.each do |i|
      fn = i.attribute('title').value
      fn.gsub!(/^producer\//, '') unless fn.blank?
      size = i.attribute('length').value.try(:to_i)
      content_type = i.attribute('type').value
      #puts "#{fn} #{size} #{content_type}"
      unless StashEngine::DataFile.where(upload_file_name: fn).where(resource_id: @resource_id).count > 0
        StashEngine::DataFile.create({
            upload_file_name: fn,
            upload_content_type: content_type,
            upload_file_size: size,
            resource_id: @resource_id,
            upload_updated_at: Time.new,
            file_state: 'created'}
        )
      end
    end
  end

  # gets the atom feed as a Nokogiri XML object
  def get_atom
    response = HTTParty.get(@atom_url)
    doc = Nokogiri::XML(response)
    doc.remove_namespaces!
  end

  def filter(noko)
    noko.xpath("//feed//link[@rel='http://purl.org/dc/terms/hasPart']" +
               "[starts-with(@href, '/d/#{CGI::escape(@ark)}/')]" +
               "[starts-with(@title, 'producer/')]"
    )
  end
end