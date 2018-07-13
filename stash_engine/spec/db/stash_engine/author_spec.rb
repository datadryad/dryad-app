require 'db_spec_helper'

module StashEngine
  describe Author do
    attr_reader :resource
    before(:each) do
      @resource = Resource.create
    end

    describe :new do
      it 'creates an author' do
        author = Author.create(
          resource_id: resource.id,
          author_first_name: 'Lise',
          author_last_name: 'Meitner',
          author_email: 'lmeitner@example.edu',
          author_orcid: '0000-0003-4293-0137'
        )
        expect(author.resource).to eq(resource)
        expect(author.author_first_name).to eq('Lise')
        expect(author.author_last_name).to eq('Meitner')
        expect(author.author_email).to eq('lmeitner@example.edu')
        expect(author.author_orcid).to eq('0000-0003-4293-0137')
        expect(author.author_full_name).to eq('Meitner, Lise')
        expect(author.author_standard_name).to eq('Lise Meitner')
        expect(author.author_html_email_string).to eq('<a href="mailto:lmeitner@example.edu">Lise Meitner</a>')
      end

      describe :author_email do
        it 'is optional' do
          author = Author.create(
            resource_id: resource.id,
            author_first_name: 'Lise',
            author_last_name: 'Meitner',
            author_orcid: '0000-0003-4293-0137'
          )
          expect(author.author_email).to be_nil
        end
      end

      describe :author_orcid do
        it 'is optional' do
          author = Author.create(
            resource_id: resource.id,
            author_first_name: 'Lise',
            author_last_name: 'Meitner',
            author_email: 'lmeitner@example.edu'
          )
          expect(author.author_orcid).to be_nil
        end
      end
    end

    describe :init_user_orcid do
      before(:each) do
        user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
        resource.user = user
        resource.save
      end

      describe 'with no user ORCiD' do
        it 'sets the user ORCiD on create' do
          author = Author.create(
            resource_id: resource.id,
            author_first_name: 'E.L.',
            author_last_name: 'Muckenhaupt',
            author_orcid: '8078-2361-3000-0000'
          )

          user = User.find(resource.user_id)
          expect(user.orcid).to eq(author.author_orcid)
        end

        it 'sets the user ORCiD on save' do
          author = Author.create(
            resource_id: resource.id,
            author_first_name: 'E.L.',
            author_last_name: 'Muckenhaupt'
          )

          author.author_orcid = '8078-2361-3000-0000'
          author.save

          user = User.find(resource.user_id)
          expect(user.orcid).to eq(author.author_orcid)
        end
      end

      describe 'with existing user ORCiD' do
        attr_reader :orcid
        before(:each) do
          @orcid = '8078-2361-3000-0000'
          user = User.find(resource.user_id)
          user.orcid = orcid
          user.save
        end

        describe 'with author ORCiD' do
          it 'leaves the user ORCiD alone on create' do
            Author.create(
              resource_id: resource.id,
              author_first_name: 'Lise',
              author_last_name: 'Meitner',
              author_orcid: '0000-0003-4293-0137'
            )
            user = User.find(resource.user_id)
            expect(user.orcid).to eq(orcid)
          end

          it 'leaves the user ORCiD alone on save' do
            author = Author.create(
              resource_id: resource.id,
              author_first_name: 'Lise',
              author_last_name: 'Meitner'
            )
            author.author_orcid = '0000-0003-4293-0137'
            author.save

            user = User.find(resource.user_id)
            expect(user.orcid).to eq(orcid)
          end
        end

        describe 'without author ORCiD' do
          it 'leaves the user ORCiD alone on create' do
            Author.create(
              resource_id: resource.id,
              author_first_name: 'Lise',
              author_last_name: 'Meitner'
            )

            user = User.find(resource.user_id)
            expect(user.orcid).to eq(orcid)
          end

          it 'leaves the user ORCiD alone on save' do
            author = Author.create(
              resource_id: resource.id,
              author_first_name: 'Lise',
              author_last_name: 'Meitner'
            )
            author.save

            user = User.find(resource.user_id)
            expect(user.orcid).to eq(orcid)
          end
        end

      end
    end
  end
end
