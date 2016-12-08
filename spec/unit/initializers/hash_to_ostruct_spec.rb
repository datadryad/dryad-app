require 'spec_helper'

describe Hash do
  describe '#to_ostruct' do
    it 'converts a Hash to an OpenStruct' do
      hash = { 'a' => 'A', 'b' => 'B' }
      ostruct = hash.to_ostruct
      expect(ostruct.a).to eq('A')
      expect(ostruct.b).to eq('B')
    end

    it 'works with symbols' do
      hash = { a: 'A', b: 'B' }
      ostruct = hash.to_ostruct
      expect(ostruct.a).to eq('A')
      expect(ostruct.b).to eq('B')
    end

    it 'converts nested hashes to nested OpenStructs' do
      hash = {
        'a' => 'A',
        'b' => {
          'c' => 'C',
          'd' => { 'e' => 'F' }
        }
      }
      ostruct = hash.to_ostruct
      expect(ostruct.b.d.e).to eq('F')
    end

    it 'converts nested hashes in arrays' do
      hash = {
        'a' => 'A',
        'b' => ['c', { 'd' => 'D', 'e' => ['f', { 'g' => 'G' }] }]
      }
      ostruct = hash.to_ostruct
      expect(ostruct.b[1].e[1].g).to eq('G')
    end
  end
end
