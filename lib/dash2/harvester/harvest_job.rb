require 'active_job'

class Dash2::Harvester::HarvestJob < ActiveJob::Base
  def perform(harvest_task)
    # TODO something like:
    #
    #   response = harvest_task.harvest
    #   response.each do |record|
    #     harvest_task.index record
    #   end
    #
    # TODO who does the looping?
    # TODO error handling?
    # TODO does index() index immediately, or schedule an index? and do we care?
  end
end

