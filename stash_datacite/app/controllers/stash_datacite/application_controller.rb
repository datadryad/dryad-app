module StashDatacite
  class ApplicationController < ::ApplicationController
    helper StashEngine::ApplicationHelper

    include StashEngine::SharedController
  end
end
