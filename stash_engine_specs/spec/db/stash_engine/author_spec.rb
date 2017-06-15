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
  end
end
