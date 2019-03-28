module MerrittHelper

  def mock_successfull_merritt_submission(resource)
    resource.current_state = 'submitted'
  end

  def mock_unsuccessfull_merritt_submission(resource)
    resource.current_state = 'error'
  end

end
