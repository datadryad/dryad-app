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
