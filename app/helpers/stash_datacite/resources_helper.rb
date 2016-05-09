module StashDatacite
  module ResourcesHelper
    def citation(creators, title, resource_type, version, identifier)
      unless creators.nil?
        creators_list = []
        creators.each do |creator|
          creators_list << "#{creator.creator_full_name} "
        end
      end
      publication_year = Time.now.year
      title = title.try(:title)
      publisher = current_tenant.try(:long_name)
      resource_type = resource_type.try(:resource_type)
      [creators_list, publication_year, title, publisher, resource_type, version, target_url(identifier)].join(', ')
    end

    def target_url(identifier)
      link_to 'http://dx.doi.org/"#{identifier}"', 'http://dx.doi.org/"#{identifier}"'
    end
  end
end
