require 'webmock/rspec'
require 'byebug'

module StashEngine
  describe Manuscript, type: :model do
    before(:each) do
    
    end

    describe '#from_message_content' do
      it 'turns a basic message into a manuscript' do
        content = "Journal Name: Royal Society Open Science\n" \
                  "Journal Code: RSOS\n" \
                  "Online ISSN: 2054-5703" \
                  "MS Reference Number: abc123" \
                  "MS Title: Some great title" \
                  "MS Authors: "
      end

      it 'provides an error when parsing fails' do
        assert(false)
      end
    end
  end
end
