class AssignHelperPointsOnRequestStopped
  def request_stopped(payload)
    request_id = payload[:request_id]

    request = Request.first(:_id => request_id)
    #update helper with points for call
    if !request.helper.nil?
      point = HelperPoint.finish_helping_request
      request.helper.helper_points.push point
      request.helper.save
    end
  end
end
