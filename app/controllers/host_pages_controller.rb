class HostPagesController < ApplicationController

  def index

  end

  def test
    @auth_hash = request.env['omniauth.auth']
  end
end
