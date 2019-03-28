module MerrittHelper

  def mock_successfull_merrit_submission(resource)
    resource.current_state = 'submitted'
  end

end
