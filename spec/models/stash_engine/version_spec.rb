
describe StashEngine do
  it 'has a version' do
    expect(StashEngine.const_defined?(:VERSION)).to be(true)
  end
end
