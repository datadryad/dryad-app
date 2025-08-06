require 'rails_helper'

module Stash
  module Import
    describe DryadManuscript do

      before(:each) do
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@datadryad.org',
                       tenant_id: 'ucop')
        @resource = create(:resource, user_id: @user.id, tenant_id: 'ucop')
        @resource.subjects = []
        @resource.authors = []
        @manuscript = create(:manuscript)
        @dm = DryadManuscript.new(resource: @resource, manuscript: @manuscript)
      end

      describe '#populate_title' do
        it 'extracts the title' do
          @dm.populate_title
          @resource.reload
          expect(@resource.title).to eql(@manuscript.metadata['ms title'])
        end
      end

      describe '#populate_abstract' do
        it 'fills in the abstract when it is supplied' do
          @dm.populate_abstract
          @resource.reload
          expect(@resource.descriptions.where(description_type: 'abstract').first.description).to eql(@manuscript.metadata['abstract'])
        end
      end

      describe '#populate_keywords' do
        it 'populates the keywords supplied' do
          @dm.populate_keywords
          @resource.reload
          @manuscript.metadata['keywords'].each_with_index do |hash_kw, index|
            expect(@resource.subjects.non_fos[index].subject).to eql(hash_kw)
          end
        end

        context 'with an existing keyword already in subjects' do
          it 'populates the remaining keywords only' do
            @manuscript.metadata['keywords'] = ["Maraj\xC3\xB3 Island"] + @manuscript.metadata['keywords']
            expect(@resource.subjects.count).to eql(0)

            @resource.subjects << create(:subject, subject: "Maraj\xC3\xB3 Island")
            @resource.reload
            expect(@resource.subjects.count).to eql(1)

            @dm.populate_keywords
            @resource.reload
            @manuscript.metadata['keywords'].each_with_index do |hash_kw, index|
              expect(@resource.subjects.non_fos[index].subject).to eql(hash_kw)
            end
            expect(@resource.subjects.count).to eql(3)
          end
        end
      end
    end
  end
end
