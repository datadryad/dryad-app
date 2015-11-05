APP_CONFIG.metadata_engines.each do |e|
e.constantize.resource_class = APP_CONFIG.shared_resource_model
end