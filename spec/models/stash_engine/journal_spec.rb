require 'rails_helper'

module StashEngine
  RSpec.describe Journal, type: :model do

    before(:each) do
      @journal = create(:journal)
      @journal2 = create(:journal)
    end

    describe '#find_by_title' do
      before(:each) do
        @alt_title = StashEngine::JournalTitle.create(title: 'An Alternate Title', journal: @journal)
      end

      it 'returns the journal for the primary title' do
        j = StashEngine::Journal.find_by_title(@journal.title)
        expect(j).to eq(@journal)
      end

      it 'returns the journal for an alternate title' do
        j = StashEngine::Journal.find_by_title(@alt_title.title)
        expect(j).to eq(@journal)
      end

      it 'returns the journal for an alternate title with an asterisk' do
        j = StashEngine::Journal.find_by_title("#{@alt_title.title}*")
        expect(j).to eq(@journal)
      end

      it 'returns nothing for a non-matching title' do
        j = StashEngine::Journal.find_by_title('non-matching title')
        expect(j).not_to eq(@journal)
      end

    end

    describe '#issn' do
      before(:each) do
        @issn1 = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
        @issn2 = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
        @issn3 = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
        @issn_distractor = "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
      end

      it 'finds by issn' do
        @journal.update(issn: @issn1)
        j = StashEngine::Journal.find_by_issn(@issn1)
        expect(j).to eq(@journal)

        j = StashEngine::Journal.find_by_issn(nil)
        expect(j).to be(nil)

        j = StashEngine::Journal.find_by_issn('notanumber')
        expect(j).to be(nil)

        j = StashEngine::Journal.find_by_issn(@issn_distractor)
        expect(j).to be(nil)
      end

      it 'finds by issn when there are multiples' do
        @journal.update(issn: [@issn1, @issn2, @issn3])
        j = StashEngine::Journal.find_by_issn(@issn1)
        expect(j).to eq(@journal)
        j = StashEngine::Journal.find_by_issn(@issn2)
        expect(j).to eq(@journal)
        j = StashEngine::Journal.find_by_issn(@issn3)
        expect(j).to eq(@journal)
        j = StashEngine::Journal.find_by_issn(@issn_distractor)
        expect(j).to be(nil)
      end

      it 'gets single_issn' do
        @journal.update(issn: @issn1)
        expect(@journal.single_issn).to eq(@issn1)

        @journal.update(issn: [@issn2, @issn3])
        expect(@journal.single_issn).to eq(@issn2)

        @journal.update(issn: nil)
        expect(@journal.single_issn).to be(nil)
      end

      it 'gets issn_array' do
        @journal.update(issn: @issn1)
        expect(@journal.issn_array).to eq([@issn1])

        @journal.update(issn: [@issn2, @issn3])
        expect(@journal.issn_array).to eq([@issn2, @issn3])

        @journal.update(issn: nil)
        expect(@journal.issn_array).to be(nil)
      end
    end

    describe '#will_pay?' do
      it 'returns true when there is a PREPAID plan' do
        allow(@journal).to receive('payment_plan_type').and_return('PREPAID')
        expect(@journal.will_pay?).to be(true)
      end

      it 'returns true when there is a SUBSCRIPTION plan' do
        allow(@journal).to receive('payment_plan_type').and_return('SUBSCRIPTION')
        expect(@journal.will_pay?).to be(true)
      end

      it 'returns false when there is a no plan' do
        allow(@journal).to receive('payment_plan_type').and_return(nil)
        expect(@journal.will_pay?).to be(false)
      end

      it 'returns false when there is an unrecognized plan' do
        allow(@journal).to receive('payment_plan_type').and_return('BOGUS-PLAN')
        expect(@journal.will_pay?).to be(false)
      end
    end

    describe '#top_level_org' do
      it 'returns nil when there is no parent org' do
        expect(@journal.top_level_org).to be(nil)
      end

      it 'returns correct top level org' do
        # single level
        parent = build(:journal_organization)
        @journal.sponsor = parent
        expect(@journal.top_level_org).to be(parent)

        # multi level
        grandparent = build(:journal_organization)
        parent.parent_org = grandparent
        expect(@journal.top_level_org).to be(grandparent)
      end
    end

  end
end
