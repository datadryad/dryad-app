class TimeInStatus
  attr_reader :activities, :return_in

  # return data based on return_in
  #  :mins  => minutes
  #  :hours => hours
  #  :days  => days
  #  nil    => seconds
  def initialize(identifier: :nil, resource: nil, return_in: nil)
    @activities = if resource.present?
                    resource.curation_activities
                  else
                    identifier.curation_activities
                  end
    @return_in = return_in
  end

  def time_in_status(statuses)
    total_time = 0
    enter_time = nil

    @activities.each do |ca|
      if ca.status.in?(statuses)
        enter_time = ca.created_at if enter_time.nil?
        next
      end

      total_time += ca.created_at.to_i - enter_time.to_i if enter_time
      enter_time = nil
    end
    readable_time total_time
  end

  def readable_time(time)
    case @return_in.to_sym
    when :mins
      (time.to_f / 60).round(2)
    when :hours
      (time.to_f / 60 / 60).round(2)
    when :days
      (time.to_f / 60 / 60 / 24).round(2)
    else
      time.to_f.round(2)
    end
  end
end
