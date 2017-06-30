require 'db_spec_helper'

module StashEngine
  describe Resource do
    attr_reader :resource
    attr_reader :primary_title
    attr_reader :user

    before(:each) do
      @user = StashEngine::User.create(
        uid: 'lmuckenhaupt-ucop@ucop.edu',
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        provider: 'developer',
        tenant_id: 'ucop'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
      @primary_title = StashDatacite::Title.create(
        resource_id: resource.id,
        title: 'An account of a very odd Monstrous Calf'
      )
    end

    describe :primary_title do
      it 'returns the primary title' do
        expect(resource.primary_title).to eq(primary_title.title)
      end
    end
  end
end
