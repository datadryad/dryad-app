RSpec.shared_examples('does not delete files') do
  after { Timecop.return }

  it 'does not delete files' do
    Timecop.travel(action_time)

    expect(double_aws).to receive(:delete_dir).never
    expect(double_aws).to receive(:delete_file).never
    task.execute
  end

  it 'does not create any new version' do
    Timecop.travel(action_time)

    expect { task.execute }.not_to(change { identifier.reload.latest_resource_id })
  end
end

RSpec.shared_examples('deletes resource files form S3') do
  after { Timecop.return }

  it 'deletes the files' do
    Timecop.travel(action_time)

    expect(double_aws).to receive(:delete_dir).at_least(:twice)
    task.execute
  end

  it 'creates a new version and sets all files as deleted' do
    Timecop.travel(action_time)
    expect(identifier.reload.latest_resource_id).to eq(resource.id)

    task.execute

    new_version = identifier.reload.latest_resource
    expect(new_version.current_state).to eq('in_progress')

    files = new_version.generic_files
    expect(files.count).to eq(3)
    expect(files.pluck(:file_state).uniq).to eq(['deleted'])
    expect(files.pluck(:file_deleted_at).compact.count).to eq(3)
  end

  it 'creates curation activity with proper notes' do
    Timecop.travel(action_time)
    task.execute

    new_version = identifier.reload.latest_resource
    expect(resource.reload.last_curation_activity.status).to eq('withdrawn')
    expect(resource.last_curation_activity.note).to eq('remove_abandoned_datasets CRON - removing data files from abandoned dataset')

    expect(new_version.last_curation_activity.status).to eq('withdrawn')
    expect(new_version.last_curation_activity.note).to eq('remove_abandoned_datasets CRON - mark files as deleted')
  end
end
