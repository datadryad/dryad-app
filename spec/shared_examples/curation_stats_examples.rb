RSpec.shared_examples('in status size for a date') do |status, method|
  it 'knows when there are none' do
    # NO -- just a normal submission
    create(:curation_activity, :submitted, resource: @res[1], user: @user, created_at: @day)

    stats = StashEngine::CurationStats.create(date: @day)
    expect(stats.send(method)).to eq(0)
  end

  it 'counts correctly when there are some' do
    stats = StashEngine::CurationStats.create(date: @day)

    # YES -- last resource status is STATUS in a past @day
    create(:curation_activity, status, resource: @res[0], user: @curator, created_at: @day - 3.days)
    stats.recalculate
    expect(stats.send(method)).to eq(1)

    # NO -- resource status changes to something else
    create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day)
    stats.recalculate
    expect(stats.send(method)).to eq(0)

    # YES -- curation to STATUS
    create(:curation_activity, status, resource: @res[2], user: @curator, created_at: @day)
    stats.recalculate
    expect(stats.send(method)).to eq(1)

    # YES -- multiple resources in STATUS in different days
    create(:curation_activity, status, resource: @res[3], user: @curator, created_at: @day - 100.days)
    create(:curation_activity, status, resource: @res[4], user: @curator, created_at: @day)
    stats.recalculate
    expect(stats.send(method)).to eq(3)

    # NO -- a new version is created
    new_version = create(:resource, identifier: @idents[4])
    create(:curation_activity, :submitted, resource: new_version, user: @curator, created_at: @day)
    stats.recalculate
    expect(stats.send(method)).to eq(2)

    # YES -- The new version is set to STATUS
    create(:curation_activity, status, resource: new_version, user: @curator, created_at: @day)
    stats.recalculate
    expect(stats.send(method)).to eq(3)

    # NO -- status is STATUS, but date is after calculation @day
    create(:curation_activity, status, resource: @res[5], user: @curator, created_at: @day + 2.days)
    stats.recalculate
    expect(stats.send(method)).to eq(3)
  end
end
