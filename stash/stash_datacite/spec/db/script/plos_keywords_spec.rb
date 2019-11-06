require 'db_spec_helper'
require 'script/plos_keywords'

module Script
  describe PlosKeywords do
    describe :populate do
      it 'creates subjects' do
        expect(StashDatacite::Subject.count).to eq(0) # just to be sure
        PlosKeywords.new('spec/data/plos_subjects.2016-4.short.tsv').populate
        expect(StashDatacite::Subject.count).to eq(186)
      end

      it 'skips existing subjects' do
        PlosKeywords.new('spec/data/plos_subjects.2016-4.shorter.tsv').populate
        expect(StashDatacite::Subject.count).to eq(33)

        PlosKeywords.new('spec/data/plos_subjects.2016-4.short.tsv').populate
        expect(StashDatacite::Subject.count).to eq(186)
      end
    end
  end
end
