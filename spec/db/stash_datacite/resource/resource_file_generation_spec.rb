require 'spec_helper'

module StashDatacite
  module Resource
    describe ResourceFileGeneration do
      attr_reader :user
      attr_reader :resource

      before(:each) do
        @user = User.create(
          uid: 'lmuckenhaupt-ucop@ucop.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          provider: 'developer',
          tenant_id: 'ucop'
        )

        @resource = Resource.create(user.uid)
        resource.ensure_identifier('')
      end

      describe '#generate_merritt_zip' do

      end
    end
  end
end
