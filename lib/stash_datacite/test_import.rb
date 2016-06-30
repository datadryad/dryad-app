require 'datacite/mapping'

module StashDatacite
  class TestImport

    def initialize(user_uid='scott.fisher-ucb@ucop.edu', xml_filename=File.join(StashDatacite::Engine.root, 'test', 'fixtures', 'datacite-example-full-v3.1.xml'))
      @user = StashEngine::User.find_by_uid(user_uid)
      @xml_str = File.read(xml_filename)
      @m_resource = Datacite::Mapping::Resource.parse_xml(@xml_str)
    end

    def populate_tables
      resource = StashEngine::Resource.create(user_id: @user.id)
      resource_state = StashEngine::ResourceState.create(user_id: @user.id, resource_state: 'submitted', resource_id: resource.id)
      resource.update(current_resource_state_id: resource_state.id)


    end

  end
end
