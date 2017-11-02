module StashDatacite
  class ApplicationController < ::ApplicationController
    helper StashEngine::ApplicationHelper

    include StashEngine::SharedController
    include StashEngine::SharedSecurityController

  end
end
