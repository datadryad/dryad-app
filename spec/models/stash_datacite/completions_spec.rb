module StashDatacite
  module Resource
    describe Completions do
      attr_reader :resource
      attr_reader :completions

      before(:each) do
        @user = create(:user)
        @resource = create(:resource, user: @user)
        @resource.save
        create(:resource_type, resource: @resource)
        create(:author, resource: @resource)
        create(:author, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        @resource.reload
        @completions = Completions.new(@resource)
      end

      describe :duplicate_submission do
        it 'detects a duplicate submission, even with a slightly different title' do
          dup = create(:resource, user: @user, title: "#{@resource.title} with a slight difference")
          expect(@completions.duplicate_submission).to eq(dup)
        end

        it 'does not register a second version as a duplicate submission' do
          create(:resource, identifier: @resource.identifier, user: @user, title: @resource.title)
          expect(@completions.duplicate_submission).to be(nil)
        end

        it 'does not register a short title as a duplicate submission' do
          @resource.update(title: 'A short title')
          create(:resource, user: @user, title: @resource.title)
          expect(@completions.duplicate_submission).to be(nil)
        end

        it 'does not register a dataset from a different submitter as a duplicate submission' do
          user2 = create(:user)
          create(:resource, user: user2, title: @resource.title)
          expect(@completions.duplicate_submission).to be(nil)
        end
      end

      describe :no_readme_md do
        before(:each) do
          @resource.data_files.first.update(upload_file_name: 'README.txt', upload_content_type: 'text/plain')
        end

        it "returns true if there is no README.md and other warning criteria are met (after date, at least one readme)" do
          @resource.identifier.update(created_at: '2022-10-31')
          expect(@completions.no_readme_md).to be(true)
        end

        it "returns false if before cutoff date" do
          @resource.identifier.update(created_at: '2022-07-31')
          expect(@completions.no_readme_md).to be(false)
        end

        it "returns false if they didn't put a readme at all since they already get other messages about that" do
          @resource.data_files.first.update(upload_file_name: 'rogaine.txt', upload_content_type: 'text/plain')
          @resource.identifier.update(created_at: '2022-10-31')
          expect(@completions.no_readme_md).to be(false)
        end

      end

      describe :related_works do
        before(:each) do
          create(:related_identifier, resource: @resource, related_identifier: Faker::Pid.doi,
                                      related_identifier_type: 'doi', relation_type: 'iscitedby',
                                      work_type: 'article', verified: true)
        end

        it 'returns true if resource has related identifiers' do
          expect(completions.has_related_works?).to be_truthy
        end

        it 'returns false if resource has no related identifiers' do
          resource.related_identifiers.each(&:destroy)
          expect(completions.has_related_works?).to be_falsey
        end

        it 'returns false if resource has no non-nil related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = nil
            rel_ident.save
          end
          expect(completions.has_related_works?).to be_falsey
        end

        it 'returns false if related_works has no non-empty related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = ''
            rel_ident.save
          end
          expect(completions.has_related_works?).to be_falsey
        end
      end

    end
  end
end
