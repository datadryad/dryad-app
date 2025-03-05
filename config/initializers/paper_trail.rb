PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  # on: %i[create update destroy],
  versions: { class_name: 'CustomVersion' },
  meta: { resource_id: proc { |record| extract_resource_id(record) } },
  ignore: [:updated_at]
}

PaperTrail.config.version_limit = nil
PaperTrail.config.serializer = PaperTrail::Serializers::JSON

def extract_resource_id(record)
  pp record

  return record.id if record.is_a?(StashEngine::Resource)
  return record.resource_id if record.respond_to?(:resource_id)
  return record.resource&.id if record.respond_to?(:resource)

  nil
end
