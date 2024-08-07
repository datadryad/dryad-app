module StashDatacite
  module Resource
    describe Completions do
      attr_reader :resource
      attr_reader :completions

      before(:each) do
        Timecop.travel(Time.now.utc - 1.day)
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
        Timecop.return
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
