RSpec.shared_examples('soft delete record') do |factory_name|
  let!(:record) { create(factory_name) }

  it 'hides deleted record' do
    expect { record.destroy }.to change(described_class, :count).by(-1)
  end

  it 'does not really delete the record' do
    expect(record.deleted?).to be_falsey
    expect { record.destroy }.to change(described_class.only_deleted, :count).by(1)
    expect(record.deleted?).to be_truthy
    expect(record.deleted_at).not_to be_nil
  end
end
