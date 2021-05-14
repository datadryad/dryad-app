require 'rails_helper'

module StashEngine

  RSpec.describe JournalOrganization, type: :model do

    before(:each) do
      @org = build(:journal_organization)
    end

    describe 'journals_sponsored' do
      it 'returns nil when there are none' do
        expect(@org.journals_sponsored).to be_nil
      end

      it 'returns sponsored journals with a direct relationship' do
        expect(@org.journals_sponsored.size).to be(1)
      end

    end

  end

end
