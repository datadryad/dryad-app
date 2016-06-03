module StashDatacite
  module ResourcesHelper
    def citation(creators, title, resource_type, version, identifier)
      unless creators.nil?
        creators_list = []
        creators.each do |creator|
          creators_list << "#{creator.creator_full_name} "
        end
      end
      publication_year = "(#{Time.now.year})"
      title = title.try(:title)
      publisher = current_tenant.try(:long_name)
      resource_type = resource_type.try(:resource_type)
      [creators_list.join(" and ").concat(publication_year), h(title), h(version), h(publisher), h(resource_type), target_url(identifier)].reject(&:blank?).join(", ").html_safe
    end

    def target_url(identifier)
      if identifier
        "#{link_to("https://dx.doi.org/#{identifier}", "https://dx.doi.org/#{identifier}", target: '_blank')} (opens in a new window)"
      else
        'https://dx.doi.org/placeholderDOI'
      end
    end
  end
end
