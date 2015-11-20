require 'rails_helper'

RSpec.describe HostPagesController, type: :controller do

  it "shows an index" do
    get :index
  end

end
