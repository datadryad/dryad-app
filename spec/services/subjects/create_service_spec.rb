module Subjects
  RSpec.describe CreateService do
    let(:resource) { create(:resource, subjects: []) }

    before { resource.resources_subjects.delete_all }

    describe 'call' do
      # removes starting and ending punctuation and spaces
      # removes duplicates
      # removes empty tags
      # removes punctuation from inside of tag
      # does not remove numbers
      # handles round brackets as delimiters
      it 'strips subject strings and removes blanks' do
        keywords = ' foo, , bar ,bz , ;tag;,[this1., tag, aa (ss) dd'.split(',')
        Subjects::CreateService.new(resource, keywords).call

        expected_array = %w[foo bar bz tag this1 aa ss dd]
        expect(resource.subjects.pluck(:subject) & expected_array).to match_array(expected_array)
      end

      it 'does not create duplicates' do
        keywords = 'aaa, aaa'
        expect do
          Subjects::CreateService.new(resource, keywords).call
        end.to change(StashDatacite::ResourcesSubjects, :count).by(1)

        expect(resource.subjects.pluck(:subject)).to eq(['aaa'])
      end

      it 'applies scope if is set' do
        keywords = %w[aaa aaa]
        expect(StashDatacite::Subject).to receive(:non_fos).twice.and_call_original
        expect do
          Subjects::CreateService.new(resource, keywords, scope: :non_fos).call
        end.to change(StashDatacite::ResourcesSubjects, :count).by(1)

        expect(resource.subjects.pluck(:subject)).to eq(['aaa'])
      end
    end
  end
end
