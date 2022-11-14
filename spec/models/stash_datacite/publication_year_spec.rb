require 'rails_helper'

module StashDatacite
  describe PublicationYear do
    before(:each) do
      user = create(:user,
                    email: 'lmuckenhaupt@example.edu',
                    tenant_id: 'dataone')
      @resource = create(:resource, user_id: user.id)
    end

    describe '#ensure_pub_year' do
      it 'sets the current year as the publication year' do
        expect(@resource.publication_years).to be_empty # just to be sure
        PublicationYear.ensure_pub_year(@resource)
        pub_year = @resource.publication_years.first
        expect(pub_year.publication_year).to eq(Time.now.year.to_s)
      end
    end
  end
end
