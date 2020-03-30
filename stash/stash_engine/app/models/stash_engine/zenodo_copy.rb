module StashEngine
  # this class has a bit of a peculiar structure and there could be multple third copy items for an identifier,
  # however there should only be one per resource (update the status and we'll have updated timestamps which is really all we need)
  # since this set of states is very simple
  class ZenodoCopy < ActiveRecord::Base

    include StashEngine::Concerns::StringEnum

    belongs_to :identifier, class_name: 'StashEngine::Identifier'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    string_enum('state', %w[enqueued replicating finished error], 'enqueued', false)

  end
end
