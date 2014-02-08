class WaitingRequests
  def get_waiting_requests_from_lasts_2_minutes
    Request.where(:stopped => false, :answered => false, :created_at.lte => 2.minutes.ago).all
  end
end