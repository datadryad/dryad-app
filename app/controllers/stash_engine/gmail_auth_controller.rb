module StashEngine
  class GmailAuthController < ApplicationController
    before_action :require_superuser

    include SharedSecurityController

    def index
      params.permit(:format)

      respond_to(&:html)
    end
  end
end
