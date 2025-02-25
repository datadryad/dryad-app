require 'stash/url_translator'

module StashEngine
  class SoftwareFilesController < GenericFilesController

    def setup_class_info
      @file_model = StashEngine::SoftwareFile
      @resource_assoc = :software_files
    end

    def license
      # write the software license to the database
      resource = StashEngine::Resource.find(params[:resource_id])
      license_id = StashEngine::SoftwareLicense.where(id: params[:license].to_i)&.first&.id
      return unless resource && license_id

      resource.identifier.update(software_license_id: license_id)
      render json: resource.identifier.software_license.to_json
    end

    def licenses
      selected = if params[:select].present?
                   StashEngine::SoftwareLicense.find(params[:select])
                 else
                   StashEngine::SoftwareLicense.find_by(identifier: 'MIT')
                 end
      render partial: 'stash_engine/shared/search_select', locals: {
        id: 'license',
        label: 'Software license:',
        field_name: 'license',
        options_path: '/software_licenses?term=',
        options_label: 'name',
        options_value: 'id',
        selected: { label: selected&.name, value: selected&.id }
      }
    end

    def licenses_autocomplete
      partial_term = params[:term]
      if partial_term.blank?
        render json: StashEngine::SoftwareLicense.limit(100)
      else
        @licenses = StashEngine::SoftwareLicense.where('LOWER(name) like LOWER(?)', "%#{partial_term}%").sort_by do |l|
          l.name.downcase.index(partial_term.downcase)
        end
        render json: @licenses
      end
    end

  end
end
