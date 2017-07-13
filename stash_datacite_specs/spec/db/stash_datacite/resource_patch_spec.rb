require 'db_spec_helper'

module StashEngine
  describe Resource do
    describe :init_author_from_user do
      attr_reader :user
      attr_reader :old_resource

      before(:each) do
        @user = User.create(
          uid: 'lmcknhpt-dataone@example.com',
          email: 'lmcknhpt@example.com',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          tenant_id: 'dataone'
        )
        @old_resource = Resource.create(user_id: user.id)
      end

      describe 'with user.orcid' do
        attr_reader :orcid

        before(:each) do
          @orcid = '8078-2361-3000-0000'
          user.orcid = orcid
          user.save!
        end

        it 'copies the most recent author with that ORCiD' do
          authors = %w[Elizabeth E.L.].map do |first_name|
            Author.create(
              resource_id: old_resource.id,
              author_orcid: orcid,
              author_first_name: first_name,
              author_last_name: 'Muckenhaupt'
            )
          end
          new_resource = Resource.create(user_id: user.id)
          new_author = Author.find_by(resource_id: new_resource.id)
          expect(new_author).not_to(be_nil)
          expect(new_author.author_orcid).to eq(orcid)
          expect(new_author.author_first_name).to eq(authors[1].author_first_name)
          expect(new_author.author_last_name).to eq(authors[1].author_last_name)
        end

        it "copies the user if there's no matching author" do
          new_resource = Resource.create(user_id: user.id)
          new_author = Author.find_by(resource_id: new_resource.id)
          expect(new_author).not_to(be_nil)
          expect(new_author.author_orcid).to eq(orcid)
          expect(new_author.author_first_name).to eq(user.first_name)
          expect(new_author.author_last_name).to eq(user.last_name)
        end
      end

      describe 'without user.orcid' do
        it "doesn't try to create an author" do
          new_resource = Resource.create(user_id: user.id)
          expect(Author.exists?(resource_id: new_resource.id)).to eq(false)
        end
      end
    end
  end
end
