class TimeInStatus
  attr_reader :activities, :return_in

  # return data based on return_in
  #  :mins  => minutes
  #  :hours => hours
  #  :days  => days
  #  nil    => seconds
  def initialize(identifier: nil, resource: nil, return_in: nil, up_to_date: nil)
    @activities = if resource.present?
                    resource.curation_activities
                  elsif identifier.present?
                    identifier.curation_activities
                  else
                    StashEngine::CurationActivity.none
                  end
    @return_in = return_in
    @up_to_date = up_to_date
  end

  # include_statuses are always related to action_taken_by if this latest is set
  # action_taken_by should be one of :dryad OR :author
  def time_in_status(statuses, include_statuses: nil, action_taken_by: nil)
    cas = curation_activities_snapshot.where.not(status: 'processing')
    total_time = 0
    enter_time = nil

    cas.each do |ca|
      if ca.status.in?(statuses)
        enter_time = ca.created_at if enter_time.nil?
        next
      end

      next if enter_time && is_in_included_statuses?(ca, include_statuses, action_taken_by)
      next unless enter_time

      total_time += ca.created_at.to_i - enter_time.to_i
      enter_time = nil
    end
    readable_time total_time
  end

  def last_time_in_status(status, include_statuses: nil, action_taken_by: nil)
    cas = curation_activities_snapshot.where.not(status: 'processing')
    enter_time = nil
    last_status_ca = cas.where(status: status).last
    return unless last_status_ca

    last_status_date = last_status_ca.created_at
    last_status_date = @up_to_date if last_status_ca == cas.last && @up_to_date

    cas.where(created_at: ..last_status_ca.created_at).each do |ca|
      # same status
      if ca.status == status
        enter_time = ca.created_at if enter_time.nil?
        next
      end
      next if enter_time && is_in_included_statuses?(ca, include_statuses, action_taken_by)

      enter_time = nil
    end
    readable_time last_status_date.to_i - enter_time.to_i
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

  private

  def is_in_included_statuses?(ca, include_statuses, action_taken_by)
    # not in included statuses
    return false unless ca.status.in?(include_statuses.to_a)

    # action actor is missing
    return true if action_taken_by.blank?

    # action is taken by proper actor
    (action_taken_by == :dryad && ca.user.min_app_admin?) ||
      (action_taken_by == :author && !ca.user.min_app_admin?)
  end

  def curation_activities_snapshot
    return @activities unless @up_to_date

    @activities.where(created_at: ..@up_to_date)
  end
end
