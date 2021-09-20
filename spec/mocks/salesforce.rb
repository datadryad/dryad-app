module Mocks

  module Salesforce

    def mock_salesforce!
      mock_case_numbers!
    end

    def mock_case_numbers!
      allow(Stash::Salesforce).to receive(:case_id).with(hash_including(case_num: '0001')).and_return(nil)
      allow(Stash::Salesforce).to receive(:case_id).with(hash_including(case_num: '0002')).and_return('abc')
    end

  end

end
