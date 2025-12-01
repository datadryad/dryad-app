# == Schema Information
#
# Table name: stash_engine_manuscripts
#
#  id                :bigint           not null, primary key
#  manuscript_number :string(191)
#  metadata          :text(16777215)
#  status            :string(191)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  identifier_id     :bigint
#  journal_id        :bigint
#
# Indexes
#
#  index_stash_engine_manuscripts_on_identifier_id  (identifier_id)
#  index_stash_engine_manuscripts_on_journal_id     (journal_id)
#
require 'webmock/rspec'
require 'byebug'

module StashEngine
  describe Manuscript, type: :model do
    let(:journal) { create(:journal) }

    describe '#from_message_content' do
      let(:title) { Faker::Lorem.sentence }
      let(:ms_number) { "ms-#{Faker::Number.number(digits: 4)}" }

      it 'turns a basic message into a manuscript' do
        content = "Journal Name: #{journal.title}\n" \
                  "Online ISSN: #{journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  "MS Title: #{title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_truthy
        expect(result.payload).not_to be_nil
        expect(result.payload.manuscript_number).to eq(ms_number)
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

      it 'provides an error when journal info missing' do
        content = "Article Status: accepted\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  "MS Title: #{title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Journal')
      end

      it 'provides an error when MS Number missing' do
        content = "Online ISSN: #{journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Title: #{title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('MS Reference Number')
      end

      it 'provides an error when Title missing' do
        content = "Online ISSN: #{journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Title')
      end

      it 'provides an error when Author info missing' do
        content = "Online ISSN: #{journal.single_issn}\n" \
                  "Article Status: accepted\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  "MS Title: #{title}\n"
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Authors')
      end

      it 'provides an error when Article Status info missing' do
        content = "Online ISSN: #{journal.single_issn}\n" \
                  "MS Reference Number: #{ms_number}\n" \
                  "MS Title: #{title}\n" \
                  'MS Authors: Lastname, Firstname; McOtherLastname, Somename'
        result = Manuscript.from_message_content(content: content)
        expect(result).not_to be_nil
        expect(result.success?).to be_falsey
        expect(result.payload).to be_nil
        expect(result.error).to include('Article Status')
      end
    end

    describe '#accepted?' do
      subject { manuscript.accepted? }

      StashEngine::Manuscript::STATUSES_MAPPING[:accepted_statuses].each do |status|
        context "when status is #{status}" do
          let(:manuscript) { create(:manuscript, status: status) }

          it { is_expected.to be_truthy }
        end
      end

      context 'when status is submitted' do
        let(:manuscript) { create(:manuscript, status: 'submitted') }

        it { is_expected.to be_falsey }

        context 'when another manuscript record is in accepted status' do
          before do
            create(:manuscript, status: 'accepted', journal_id: manuscript.journal_id, identifier_id: manuscript.identifier_id,
                                manuscript_number: manuscript.manuscript_number)
            create(:manuscript, status: 'submitted', journal_id: manuscript.journal_id, identifier_id: manuscript.identifier_id,
                                manuscript_number: manuscript.manuscript_number)
          end

          it { is_expected.to be_truthy }
        end
      end
    end

    describe '#rejected?' do
      subject { manuscript.rejected? }

      StashEngine::Manuscript::STATUSES_MAPPING[:rejected_statuses].each do |status|
        context "when status is #{status}" do
          let(:manuscript) { create(:manuscript, status: status) }

          it { is_expected.to be_truthy }
        end
      end

      context 'when status is submitted' do
        let(:manuscript) { create(:manuscript, status: 'submitted') }

        it { is_expected.to be_falsey }

        context 'when another manuscript record is in rejected status' do
          before do
            create(:manuscript, status: 'rejected', journal_id: manuscript.journal_id, identifier_id: manuscript.identifier_id,
                                manuscript_number: manuscript.manuscript_number)
            create(:manuscript, status: 'submitted', journal_id: manuscript.journal_id, identifier_id: manuscript.identifier_id,
                                manuscript_number: manuscript.manuscript_number)
          end

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
