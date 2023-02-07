require 'webmock/rspec'
require 'byebug'

module StashEngine
  describe Manuscript, type: :model do
    before(:each) do
      @journal = create(:journal)
    end

    describe '#from_message_content' do
      before(:each) do
        @ms_number = "ms-#{Faker::Number.number(digits: 4)}"
        @title = Faker::Lorem.sentence
      end

      it 'turns a basic message into a manuscript' do
        content = "Journal Name: #{@journal.title}\n" \
                  "Online ISSN: #{@journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{@ms_number}\n" \
                  "MS Title: #{@title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_truthy
        expect(result.payload).not_to be_nil
        expect(result.payload.manuscript_number).to eq(@ms_number)
        expect(result.payload.metadata['ms title']).to eq(@title)
      end

      it 'provides an error when parsing fails' do
        content = 'abc'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).not_to be_nil
      end

      it 'provides an error when journal info missing' do
        content = "Article Status: accepted\n" \
                  "MS Reference Number: #{@ms_number}\n" \
                  "MS Title: #{@title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Journal')
      end

      it 'provides an error when MS Number missing' do
        content = "Online ISSN: #{@journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Title: #{@title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('MS Reference Number')
      end

      it 'provides an error when Title missing' do
        content = "Online ISSN: #{@journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{@ms_number}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Title')
      end

      it 'provides an error when Author info missing' do
        content = "Online ISSN: #{@journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{@ms_number}\n" \
                  "MS Title: #{@title}\n"
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Authors')
      end

      it 'provides an error when Article Status info missing' do
        content = "Online ISSN: #{@journal.single_issn}\n" \
                  "MS Reference Number: #{@ms_number}\n" \
                  "MS Title: #{@title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Article Status')
      end

    end
  end
end
