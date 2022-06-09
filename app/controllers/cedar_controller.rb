class CedarController < ApplicationController
  def save
    puts "I'M IN THE CEDAR SAVE CONTROLLER"
    respond_to do |format|
      format.any { render json: { message: 'Save value received in the Cedar Save method' } }
    end
  end
end
