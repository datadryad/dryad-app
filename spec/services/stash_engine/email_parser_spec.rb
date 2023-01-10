module StashEngine
  describe EmailParser do

    describe '#metadata_basics' do
      it 'does not return content when there are no parseable values' do
        content = "Journal: Royal Society Open Science\nSome other garbage"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash.size).to eq(0)
      end

      it 'turns a basic message into a hash' do
        content = "Journal name: Royal Society Open Science\nJournal Code: RSOS\nOnline ISSN: 2054-5703"
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['journal code']).to eq('rsos')
      end

      it 'turns an HTML message into a hash' do
        content = 'Journal name: Royal Society Open Science<br/>Journal Code: RSOS<br />Online ISSN: 2054-5703'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['journal code']).to eq('rsos')
      end

      it 'ignores content after the EndDryadContent tag' do
        content = 'Journal name: Royal Society Open Science<br/>EndDryadContent<br/>Journal Code: RSOS<br />Online ISSN: 2054-5703'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['journal code']).to be_nil
      end
    end

    describe '#identifier' do
      it 'finds identifier from data DOI' do
        ident = create(:identifier)
        content = "Dryad Data DOI: doi:#{ident.identifier}"
        parser = EmailParser.new(content: content)
        expect(parser.identifier).to eq(ident)
      end

      it 'finds identifier from manuscript number' do
        ident = create(:identifier)
        journal = create(:journal)
        ms_number = "ms-#{Faker::Number.number(digits: 4)}"
        create(:internal_data, identifier_id: ident.id, data_type: 'manuscriptNumber', value: ms_number)
        create(:internal_data, identifier_id: ident.id, data_type: 'publicationISSN', value: journal.issn)
        content = "Online ISSN: #{journal.issn}\nMS Reference Number: #{ms_number}"
        parser = EmailParser.new(content: content)
        expect(parser.identifier).to eq(ident)
      end
    end

    describe '#journal' do
      before(:each) do
        @journal = create(:journal)
      end

      it 'finds journal from print ISSN' do
        content = "Print ISSN: #{@journal.issn}"
        parser = EmailParser.new(content: content)
        expect(parser.journal).to eq(@journal)
      end

      it 'finds journal from online ISSN' do
        content = "Print ISSN: 1234-1234\nOnline ISSN: #{@journal.issn}"
        parser = EmailParser.new(content: content)
        expect(parser.journal).to eq(@journal)
      end

      it 'finds journal from journal code' do
        content = "Journal Code: #{@journal.journal_code}"
        parser = EmailParser.new(content: content)
        expect(parser.journal).to eq(@journal)
      end

      it 'applies the manuscript_number_regex to clean manuscript numbers' do
        regex = '.*?(\d+-\d+).*?'
        @journal.manuscript_number_regex = regex
        @journal.save
        ms_number = "ABC#{Faker::Number.number(digits: 2)}-#{Faker::Number.number(digits: 4)}.R2"
        target_ms_number = ms_number.match(regex)[1]
        content = "Journal Code: #{@journal.journal_code}\nMS Reference Number: #{ms_number}"
        parser = EmailParser.new(content: content)
        expect(parser.manuscript_number).to eq(target_ms_number)
      end
    end

    describe '#authors' do
      it 'parses authors with "last, first", separated by semicolons' do
        content = 'MS Authors: last, first; last2, first2'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['ms authors']).not_to be_nil
        expect(hash['ms authors'].size).to eq(2)
        expect(hash['ms authors'][0]['family_name']).to eq('last')
      end

      it 'parses authors with "first last, first last", separated by commas' do
        content = 'MS Authors: first last, first2 last2, first3 last3'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['ms authors']).not_to be_nil
        expect(hash['ms authors'].size).to eq(3)
        expect(hash['ms authors'][0]['family_name']).to eq('last')
        expect(hash['ms authors'][1]['family_name']).to eq('last2')
        expect(hash['ms authors'][2]['family_name']).to eq('last3')
      end

      it 'parses authors with "first last, first last", with "and" at the end' do
        content = 'MS Authors: first last, first2 last2 and first3 last3'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['ms authors']).not_to be_nil
        expect(hash['ms authors'].size).to eq(3)
        expect(hash['ms authors'][0]['family_name']).to eq('last')
        expect(hash['ms authors'][1]['family_name']).to eq('last2')
        expect(hash['ms authors'][2]['family_name']).to eq('last3')
      end

      it 'parses authors with "first last", keeping suffixes and dropping titles' do
        content = 'MS Authors: first last, Jr.; first2 last2, PhD; Ms. first3 last3'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['ms authors']).not_to be_nil
        expect(hash['ms authors'].size).to eq(3)
        expect(hash['ms authors'][0]['family_name']).to eq('last, Jr.')
        expect(hash['ms authors'][1]['family_name']).to eq('last2')
        expect(hash['ms authors'][2]['given_name']).to eq('first3')
        expect(hash['ms authors'][2]['family_name']).to eq('last3')
      end

      it 'parses authors with a single name' do
        content = 'MS Authors: Elvis Presley and Cher'
        parser = EmailParser.new(content: content)
        hash = parser.metadata_hash

        expect(hash['ms authors']).not_to be_nil
        expect(hash['ms authors'].size).to eq(2)
        expect(hash['ms authors'][0]['family_name']).to eq('Presley')
        expect(hash['ms authors'][1]['given_name']).to eq('')
        expect(hash['ms authors'][1]['family_name']).to eq('Cher')
      end
    end
  end
end
