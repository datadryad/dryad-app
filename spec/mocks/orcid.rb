module Mocks

  module Orcid

    WebMock.disable_net_connect!(allow: ['127.0.0.1', 'api.sandbox.orcid.org'])

  end

end