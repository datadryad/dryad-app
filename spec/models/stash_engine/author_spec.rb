module StashEngine
  describe Author do

    before(:each) do
      @ident = create(:identifier)
      @resource = create(:resource,
                         identifier: @ident,
                         tenant_id: 'dryad')
    end

    describe :new do
      it 'creates an author' do
        author = create(:author,
                        resource: @resource,
                        author_first_name: 'Lise',
                        author_last_name: 'Meitner',
                        author_email: 'lmeitner@example.edu',
                        author_orcid: '0000-0003-4293-0137')
        expect(author.resource).to eq(@resource)
        expect(author.author_first_name).to eq('Lise')
        expect(author.author_last_name).to eq('Meitner')
        expect(author.author_email).to eq('lmeitner@example.edu')
        expect(author.author_orcid).to eq('0000-0003-4293-0137')
        expect(author.author_full_name).to eq('Meitner, Lise')
        expect(author.author_standard_name).to eq('Lise Meitner')
        expect(author.author_html_email_string).to eq('<a href="mailto:lmeitner@example.edu">Lise Meitner</a>')
      end

      describe :ordering do
        before(:each) do
          @resource.authors.destroy_all
          temp_auths = Array.new(7) { |_i| create(:author, resource_id: @resource.id) }
          @authors = temp_auths.shuffle
          @authors.each_with_index { |auth, idx| auth.update(author_order: idx) }
        end

        it 'orders by the author_order instead of id if it is set' do
          @retrieved_authors = Author.where(resource_id: @resource.id)
          @retrieved_authors.each_with_index do |ret, idx|
            expect(ret.id).to eq(@authors[idx].id)
          end
        end
      end

      describe :author_email do
        it 'is optional' do
          author = Author.create(
            resource: @resource,
            author_first_name: 'Lise',
            author_last_name: 'Meitner',
            author_orcid: '0000-0003-4293-0137'
          )
          expect(author.author_email).to be_nil
        end
      end

      describe :orcid_invite_path do
        it 'generates an orcid_invite_path when needed' do
          author = create(:author)
          expect(author.orcid_invite_path).to include('invitation')
        end

        it 'delivers the correct orcid_invite_path' do
          author = create(:author,
                          resource: @resource)
          orcid_invite = StashEngine::OrcidInvitation.create(
            email: author.author_email,
            identifier_id: @resource.identifier_id,
            first_name: author.author_first_name,
            last_name: author.author_last_name,
            secret: SecureRandom.urlsafe_base64,
            invited_at: Time.new.utc
          )

          expect(author.orcid_invite_path).to include("invitation=#{orcid_invite.secret}")
          expect(author.orcid_invite_path).to include(@resource.identifier.identifier)
        end
      end

      describe :author_orcid do
        it 'is optional' do
          author = Author.create(
            resource: @resource,
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
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@ucop.edu',
                       tenant_id: 'ucop',
                       orcid: nil)
        @resource.user = @user
        @resource.save
      end

      describe 'with no user ORCiD' do
        it 'sets the user ORCiD on create' do
          author = create(:author,
                          resource: @resource,
                          author_first_name: 'E.L.',
                          author_last_name: 'Muckenhaupt',
                          author_orcid: '8078-2361-3000-0000')
          author.save
          @resource.reload

          user = User.find(@resource.user_id)
          expect(user.orcid).to eq(author.author_orcid)
        end

        it 'sets the user ORCiD on save' do
          author = Author.create(
            resource: @resource,
            author_first_name: 'E.L.',
            author_last_name: 'Muckenhaupt'
          )

          author.author_orcid = '8078-2361-3000-0000'
          author.save

          user = User.find(@resource.user_id)
          expect(user.orcid).to eq(author.author_orcid)
        end
      end

      describe 'with existing user ORCiD' do
        before(:each) do
          @orcid = '8078-2361-3000-0000'
          @user = User.find(@resource.user_id)
          @user.orcid = @orcid
          @user.save
        end

        describe 'with author ORCiD' do
          it 'leaves the user ORCiD alone on create' do
            create(:author,
                   resource: @resource,
                   author_first_name: 'Lise',
                   author_last_name: 'Meitner',
                   author_orcid: '0000-0003-4293-0137')
            expect(@user.orcid).to eq(@orcid)
          end

          it 'leaves the user ORCiD alone on save' do
            author = create(:author,
                            resource: @resource,
                            author_first_name: 'Lise',
                            author_last_name: 'Meitner')
            author.author_orcid = '0000-0003-4293-0137'
            author.save

            expect(@user.orcid).to eq(@orcid)
          end
        end

        describe 'without author ORCiD' do
          it 'leaves the user ORCiD alone on create' do
            Author.create(
              resource: @resource,
              author_first_name: 'Lise',
              author_last_name: 'Meitner'
            )

            user = User.find(@resource.user_id)
            expect(user.orcid).to eq(@orcid)
          end

          it 'leaves the user ORCiD alone on save' do
            author = Author.create(
              resource: @resource,
              author_first_name: 'Lise',
              author_last_name: 'Meitner'
            )
            author.save

            user = User.find(@resource.user_id)
            expect(user.orcid).to eq(@orcid)
          end
        end

      end
    end
  end
end
