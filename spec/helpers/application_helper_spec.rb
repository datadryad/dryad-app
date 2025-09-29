require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'name_reverser' do
    context 'when name is blank' do
      it 'returns not set' do
        expect(helper.name_reverser('')).to eq('[Name not set]')
      end
    end
    context 'when name exists' do
      let(:name) { 'Person, Test' }
      it 'reverses the name' do
        expect(helper.name_reverser(name)).to eq('Test Person')
      end
    end
  end
end
