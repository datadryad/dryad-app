module StashEngine
  module AdminDatasetsHelper

    def institution_select
      StashEngine::Tenant.all.map { |item| [item.short_name, item.tenant_id] }
    end

    def status_select
      CurationActivity.validators_on(:status).first.options[:in]
    end

  end
end
