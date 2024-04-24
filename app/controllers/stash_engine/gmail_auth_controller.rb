module StashEngine
  class GmailAuthController < ApplicationController
    include SharedSecurityController
    before_action :require_superuser

    def index
      params.permit(:format)

      respond_to(&:html)
    end
  end
end
