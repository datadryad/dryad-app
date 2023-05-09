module StashEngine
  class GmailAuthController < ApplicationController
    def index
      authorize %i[stash_engine gmail_auth_policy], :index?
      params.permit(:format)

      respond_to(&:html)
    end
  end
end
