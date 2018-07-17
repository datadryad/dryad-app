require 'db_spec_helper'

module StashDatacite
  describe PublicationYear do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#ensure_pub_year' do
      it 'sets the current year as the publication year' do
        expect(resource.publication_years).to be_empty # just to be sure
        PublicationYear.ensure_pub_year(resource)
        pub_year = resource.publication_years.first
        expect(pub_year.publication_year).to eq(Time.now.year.to_s)
      end
    end
  end
end
