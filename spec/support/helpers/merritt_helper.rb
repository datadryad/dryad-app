module MerrittHelper

  def mock_merritt_send!(resource)
    create(:curation_activity, status: 'processing', resource: resource)
    resource.save
    resource.reload
  end

  def mock_successfull_merritt_submission!(resource)
    resource.current_state = 'submitted'
    resource.save
    resource.reload
  end

  def mock_unsuccessfull_merritt_submission!(resource)
    resource.current_state = 'error'
    resource.save
    resource.reload
  end

end
