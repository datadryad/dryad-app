require 'webmock/rspec'
require 'byebug'

module StashEngine
  describe Manuscript, type: :model do
    before(:each) do
      @journal = create(:journal)
    end

    describe '#from_message_content' do
      it 'turns a basic message into a manuscript' do
        ms_number = "ms-#{Faker::Number.number(digits: 4)}"
        title = Faker::Lorem.sentence
        content = "Journal Name: #{@journal.title}\n" \
                  "Journal Code: RSOS\n" \
                  "Online ISSN: #{@journal.issn}\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  "MS Title: #{title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_truthy
        expect(result.payload).not_to be_nil
        expect(result.payload.manuscript_number).to eq(ms_number)
        puts("PAYLmmet #{result.payload.metadata} -- #{title}")
        expect(result.payload.metadata['ms title']).to eq(title)
      end

      it 'provides an error when parsing fails' do
        content = 'abc'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).not_to be_nil
      end
    end
  end
end
