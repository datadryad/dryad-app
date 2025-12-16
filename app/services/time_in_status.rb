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

  # include_statuses are always related to action_taken_by if this latest is set
  # action_taken_by should be one of :dryad OR :author
  def time_in_status(statuses, include_statuses: nil, action_taken_by: nil)
    total_time = 0
    enter_time = nil

    @activities.each do |ca|
      if ca.status.in?(statuses)
        enter_time = ca.created_at if enter_time.nil?
        next
      end

      if include_statuses && enter_time && ca.status.in?(include_statuses)
        if action_taken_by.present?
          if (action_taken_by == :dryad && ca.user.min_app_admin?) ||
            (action_taken_by == :author && !ca.user.min_app_admin?)
            enter_time = ca.created_at if enter_time.nil?
            next
          end
        else
          enter_time = ca.created_at if enter_time.nil?
          next
        end
      end

      next unless enter_time

      total_time += ca.created_at.to_i - enter_time.to_i
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
