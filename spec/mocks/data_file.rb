module Mocks

  module DataFile
    def mock_file_content!
      # file content can have 2 different HTTP requests and stubbing doesn't seem to work
      allow_any_instance_of(StashEngine::DataFile).to receive(:file_content).and_return('### This is a test README title')
    end
  end
end
