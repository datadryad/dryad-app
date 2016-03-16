module StashDatacite
  module ResourcesHelper
    def citation(creators, title, resource_type)
      unless creators.nil?
        creators_list = []
        creators.each do |creator|
          creators_list << "#{creator.creator_full_name} "
        end
      end
      publication_year  = Time.now.year
      title = title.try(:title)
      publisher = current_tenant.try(:long_name)
      resource_type = resource_type.try(:resource_type)
      identifier = "DOI"
      return [creators_list, publication_year, title, publisher, resource_type, identifier].join(", ")
    end
  end
end
