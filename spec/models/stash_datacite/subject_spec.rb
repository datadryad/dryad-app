# == Schema Information
#
# Table name: dcs_subjects
#
#  id             :integer          not null, primary key
#  scheme_URI     :text(65535)
#  subject        :text(65535)
#  subject_scheme :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_dcs_subjects_on_subject  (subject)
#
module StashDatacite
  module Resource
    describe Subject do
      it 'leaves out FOS items with .non_fos scope' do
        items = [create(:subject), create(:subject), create(:subject, subject_scheme: 'fos')]
        expect(Subject.all.length).to eq(items.length)
        expect(Subject.all.non_fos.length).to eq(items.length - 1)
      end
    end
  end
end
