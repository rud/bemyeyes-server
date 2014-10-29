class WaitingRequests
  #http://stackoverflow.com/questions/2943222/find-objects-between-two-dates-mongodb
  def get_waiting_requests_from_lasts_2_minutes
    Request.where(:stopped => false, :answered => false, :created_at.gt => 2.minutes.ago.utc).all
  end
end
