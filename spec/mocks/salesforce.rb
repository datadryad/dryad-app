module Mocks

  module Salesforce

    def mock_salesforce!
      allow(Stash::Salesforce).to receive(:sf_client).and_return(nil)
      mock_case_numbers!
      mock_case_find!
    end

    def mock_case_numbers!
      allow(Stash::Salesforce).to receive(:case_id).with(hash_including(case_num: '0001')).and_return(nil)
      allow(Stash::Salesforce).to receive(:case_id).with(hash_including(case_num: '0002')).and_return('abc')
    end

    def mock_case_find!
      result = [{ title: 'SF 0003', path: 'https://dryad.lightning.force.com/lightning/r/Case/abc1/view' }.to_ostruct]
      allow(Stash::Salesforce).to receive(:find_cases_by_doi).and_return(result)
    end
  end

end
