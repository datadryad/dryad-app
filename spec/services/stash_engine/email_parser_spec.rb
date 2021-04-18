module StashEngine
  describe EmailParser do
    before(:each) do
    end

    describe '#metadata_hash' do
      it 'does not return content when there are no parseable values' do
        content = "Journal: Royal Society Open Science\nSome other garbage"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash
        
        expect(hash.size).to eq(0)
      end
     
      it 'turns a basic message into a hash' do
        content = "Journal Name: Royal Society Open Science\nJournal Code: RSOS\nOnline ISSN: 2054-5703"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['journal code']).to eq('RSOS')
      end

      it 'turns an HTML message into a hash' do
        content = "Journal Name: Royal Society Open Science<br/>Journal Code: RSOS<br />Online ISSN: 2054-5703"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash
        
        expect(hash['journal code']).to eq('RSOS')
      end

      it 'ignores content after the EndDryadContent tag' do
        content = "Journal Name: Royal Society Open Science<br/>EndDryadContent<br/>Journal Code: RSOS<br />Online ISSN: 2054-5703"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash
        
        expect(hash['journal code']).to eq(nil)
      end
      
    end
  end
end

