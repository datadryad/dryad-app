# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  allow_review_workflow   :boolean          default(TRUE)
#  api_contacts            :text(65535)
#  covers_ldf              :boolean          default(FALSE)
#  default_to_ppr          :boolean          default(FALSE)
#  description             :text(65535)
#  journal_code            :string(191)
#  manuscript_number_regex :string(191)
#  notify_contacts         :text(65535)
#  payment_plan_type       :string
#  peer_review_custom_text :text(65535)
#  preprint_server         :boolean          default(FALSE)
#  review_contacts         :text(65535)
#  title                   :string(191)
#  website                 :string(191)
#  created_at              :datetime
#  updated_at              :datetime
#  sponsor_id              :integer
#  stripe_customer_id      :string(191)
#
# Indexes
#
#  index_stash_engine_journals_on_title  (title)
#
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
        @journal = create(:journal, issn: @issn1)
      end

      it 'finds by issn' do
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
        [@issn2, @issn3].each { |id| create(:journal_issn, journal: @journal, id: id) }
        @journal.reload
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
        expect(@journal.single_issn).to eq(@issn1)

        @journal.issns.destroy_all
        create(:journal_issn, journal: @journal, id: @issn2)
        create(:journal_issn, journal: @journal, id: @issn3)
        @journal.reload
        expect(@journal.single_issn).to eq(@issn2)

        @journal.issns.destroy_all
        @journal.reload
        expect(@journal.single_issn).to be(nil)
      end

      it 'gets issn_array' do
        expect(@journal.issn_array).to eq([@issn1])

        @journal.issns.destroy_all
        create(:journal_issn, journal: @journal, id: @issn2)
        create(:journal_issn, journal: @journal, id: @issn3)
        @journal.reload
        expect(@journal.issn_array).to eq([@issn2, @issn3])

        @journal.issns.destroy_all
        @journal.reload
        expect(@journal.issn_array).to be_empty
      end
    end

    describe '#will_pay?' do
      StashEngine::Journal::PAYMENT_PLANS.each do |plan|
        it "returns true when there is a #{plan} plan" do
          create(:payment_configuration, partner: @journal, payment_plan: plan)
          expect(@journal.will_pay?).to be(true)
        end
      end

      it 'returns false when there is a no plan' do
        create(:payment_configuration, partner: @journal, payment_plan: nil)
        expect(@journal.will_pay?).to be(false)
      end

      it 'returns false when there is an unrecognized plan' do
        pc = create(:payment_configuration, partner: @journal)
        allow(pc).to receive(:payment_plan).and_return('BOGUS-PLAN')
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
